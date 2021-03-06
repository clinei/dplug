/**
* Copyright: Copyright Auburn Sounds 2015-2016
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module dplug.core.funcs;

import std.math;

version(LDC)
{
    import ldc.intrinsics;
}

immutable real TAU = PI * 2;

/** Four Character Constant (for AEffect->uniqueID) */
int CCONST(int a, int b, int c, int d) pure nothrow
{
    return (a << 24) | (b << 16) | (c << 8) | (d << 0);
}

/// Map linearly x from the range [a, b] to the range [c, d]
T linmap(T)(T value, T a, T b, T c, T d) pure nothrow @nogc
{
    return c + (d - c) * (value - a) / (b - a);
}

/// map [0..1] to [min..max] logarithmically
/// min and max must be all > 0, t in [0..1]
T logmap(T)(T t, T min, T max) pure nothrow @nogc
{
    assert(min < max);
    return min * exp(t * log(max / min));
}

/// Hermite interpolation.
T hermite(T)(T frac_pos, T xm1, T x0, T x1, T x2) pure nothrow @nogc
{
    T c = (x1 - xm1) * 0.5f;
    T v = x0 - x1;
    T w = c + v;
    T a = w + v + (x2 - x0) * 0.5f;
    T b_neg = w + a;
    return ((((a * frac_pos) - b_neg) * frac_pos + c) * frac_pos + x0);
}

/// Convert from dB to float.
T deciBelToFloat(T)(T dB) pure nothrow @nogc
{
    static immutable T ln10_20 = cast(T)LN10 / 20;
    return exp(dB * ln10_20);
}

/// Convert from float to dB
T floatToDeciBel(T)(T x) pure nothrow @nogc
{
    static immutable T f20_ln10 = 20 / cast(T)LN10;
    return log(x) * f20_ln10;
}

/// Is this integer odd?
bool isOdd(T)(T i) pure nothrow @nogc
{
    return (i & 1) != 0;
}

/// Is this integer even?
bool isEven(T)(T i) pure nothrow @nogc
{
    return (i & 1) == 0;
}

/// Returns: x so that (1 << x) >= i
int iFloorLog2(int i) pure nothrow @nogc
{
    assert(i >= 1);
    int result = 0;
    while (i > 1)
    {
        i = i / 2;
        result = result + 1;
    }
    return result;
}

/// Mapping from MIDI notes to frequency
double MIDIToFrequency(T)(int note) pure nothrow @nogc
{
    return 440 * pow(2.0, (note - 69.0) / 12.0);
}

/// Mapping from frequency to MIDI notes
double frequencyToMIDI(T)(double frequency) pure nothrow @nogc
{
    return 69.0 + 12 * log2(frequency / 440.0);
}

/// Fletcher and Munson equal-loudness curve
/// Reference: Xavier Serra thesis (1989).
T equalLoudnessCurve(T)(T frequency) pure nothrow @nogc
{
    T x = cast(T)0.05 + 4000 / frequency;
    return x * ( cast(T)10 ^^ x);
}

/// Cardinal sine
T sinc(T)(T x) pure nothrow @nogc
{
    if (cast(T)(1) + x * x == cast(T)(1))
        return 1;
    else
        return sin(cast(T)PI * x) / (cast(T)PI * x);
}

double expDecayFactor(double time, double samplerate) pure nothrow @nogc
{
    // 1 - exp(-time * sampleRate) would yield innacuracies
    return -expm1(-1.0 / (time * samplerate));
}

/// Give back a phase between -PI and PI
T normalizePhase(T)(T phase) nothrow @nogc
{
    enum bool Assembly = D_InlineAsm_Any && !(is(Unqual!T == real));

    static if (Assembly)
    {
        T k_TAU = PI * 2;
        T result = phase;
        asm nothrow @nogc
        {
            fld k_TAU;    // TAU
            fld result;    // phase | TAU
            fprem1;       // normalized(phase) | TAU
            fstp result;   // TAU
            fstp ST(0);   //
        }
        return result;
    }
    else
    {
        T res = fmod(phase, cast(T)TAU);
        if (res > PI)
            res -= TAU;
        if (res < -PI)
            res += TAU;
        return res;
    }
}

unittest
{
    assert(approxEqual(normalizePhase!real(TAU), 0));

    assert(approxEqual(normalizePhase!float(0.1f), 0.1f));
    assert(approxEqual(normalizePhase!float(TAU + 0.1f), 0.1f));

    assert(approxEqual(normalizePhase!double(-0.1f), -0.1f));
    assert(approxEqual(normalizePhase!double(-TAU - 0.1f), -0.1f));

    bool approxEqual(T)(T a, T b) nothrow @nogc
    {
        return (a - b) < 1e-7;
    }
}

/// Quick and dirty sawtooth for testing purposes.
T rawSawtooth(T)(T x) pure nothrow @nogc
{
    return normalizePhase(x) / (cast(T)PI);
}

/// Quick and dirty triangle for testing purposes.
T rawTriangle(T)(T x) pure nothrow @nogc
{
    return 1 - normalizePhase(x) / cast(T)PI_2;
}

/// Quick and dirty square for testing purposes.
T rawSquare(T)(T x) pure nothrow @nogc
{
    return normalizePhase(x) > 0 ? 1 : -1;
}

T computeRMS(T)(T[] samples) pure nothrow @nogc
{
    double sum = 0;
    foreach(sample; samples)
        sum += sample * sample;
    return sqrt(sum / cast(int)samples.length);
}

unittest
{
    double[] d = [4, 5, 6];
    computeRMS(d);
}


/// Use throughout dplug:dsp to avoid reliance on GC.
/// This works like alignedRealloc except with slices as input.
///
/// Params:
///    buffer Existing allocated buffer. Can be null. Input slice length is not considered.
///    length desired slice length
///
void reallocBuffer(T)(ref T[] buffer, size_t length, int alignment = 16) nothrow @nogc
{
    import gfm.core.memory : alignedRealloc;

    T* pointer = cast(T*) alignedRealloc(buffer.ptr, T.sizeof * length, alignment);
    if (pointer is null)
        buffer = null;
    else
        buffer = pointer[0..length];
}

/// A bit faster than a dynamic cast.
/// This is to avoid TypeInfo look-up
T unsafeObjectCast(T)(Object obj)
{
    return cast(T)(cast(void*)(obj));
}

/// To call for something that should never happen, but we still
/// want to make a "best effort" at runtime even if it can be meaningless.
/// TODO: change that name, it's not actually unrecoverable
void unrecoverableError() nothrow @nogc
{
    debug
    {
        // Crash unconditionally
        assert(false); 
    }
    else
    {
        // There is a trade-off here, if we crash immediately we will be 
        // correctly identified by the user as the origin of the bug, which
        // is always helpful.
        // But crashing may in many-case also crash the host, which is not very friendly.
        // Eg: a plugin not instancing vs host crashing.
        // The reasoning is that the former is better from the user POV.
    }
}

// Copy source into dest.
// dest must contain room for maxChars characters
// A zero-byte character is then appended.
void stringNCopy(char* dest, size_t maxChars, string source) nothrow @nogc
{
    if (maxChars == 0)
        return;

    size_t max = maxChars < source.length ? maxChars - 1 : source.length;
    for (int i = 0; i < max; ++i)
        dest[i] = source[i];
    dest[max] = '\0';
}

version(D_InlineAsm_X86)
    private enum D_InlineAsm_Any = true;
else version(D_InlineAsm_X86_64)
    private enum D_InlineAsm_Any = true;
else
    private enum D_InlineAsm_Any = false;

// These functions trade correctness for speed
// The contract is that they don't check for infinity or NaN
// and assume small finite numbers instead.
// Don't rely on them being correct for your situation: test them.

///
T fast_pow(T)(T val, T power)
{
    version(LDC)
        return llvm_pow(val, power);
    else
        return pow(val, power);
}

///
T fast_exp(T)(T val, T)
{
    version(LDC)
        return llvm_exp(val);
    else
        return exp(val);
}

///
T fast_log(T)(T val)
{
    version(LDC)
        return llvm_log(val);
    else
        return log(val);
}

///
T fast_floor(T)(T val)
{
    version(LDC)
        return llvm_floor(val);
    else
        return log(val);
}

///
T fast_ceil(T)(T val)
{
    version(LDC)
        return llvm_ceil(val);
    else
        return ceil(val);
}

///
T fast_trunc(T)(T val)
{
    version(LDC)
        return llvm_trunc(val);
    else
        return trunc(val);
}

///
T fast_round(T)(T val)
{
    version(LDC)
        return llvm_round(val);
    else
        return round(val);
}

///
T fast_exp2(T)(T val)
{
    version(LDC)
        return llvm_exp2(val);
    else
        return exp2(val);
}

///
T fast_log10(T)(T val)
{
    version(LDC)
        return llvm_log10(val);
    else
        return log10(val);
}

///
T fast_log2(T)(T val)
{
    version(LDC)
        return llvm_log2(val);
    else
        return log2(val);
}
