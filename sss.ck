//-----------------------------------------------------------------------------
// name: sss.ck
// desc: sonic solar system (SSS) visualizes the spectrum of audio samples in real time by breaking the human auditory frequency spectrum into 8 bins and correlating the total acoustic energy/amplitude of that bin to the size if the planet and the speed of its orbit. The trail of moons for each planet records the spectral history.  

//
// author: Udbhav Venkataraman
// date: Fall 2026
//-----------------------------------------------------------------------------
// scene setup

// window title
GWindow.title( "sonic orbit" );

// Global Variables
1024 => int WINDOW_SIZE;
0 => float WAVEFORM_Y;
0 => int playMusic;
10 => float DISPLAY_WIDTH;
.5 => float REVOLVE_FACTOR;
10 => int NUM_MOONS;
.1 => float MOON_INTERVAL;
150::ms => dur BEEP_TIME;
[-5, -2, 0, 5, 7, 9, 12, 14] @=> int notes[]; 
56 => int offset;
float prevPosX[8];

// Set bloom for all objects
GG.bloom(true);
GG.bloomPass() @=> BloomPass bloom_pass;
bloom_pass.intensity(.5); 

// PlanetSys class inherits from GGen and has methods related to the moon spectral history setup
class PlanetSys extends GGen
{
    0 => int playhead;
    0.0 => float distance;
    GSphere moons[NUM_MOONS];

    for(0 => int i; i < NUM_MOONS; i++)
    {
        moons[i] --> this;
        moons[i].sca(@(0.1, 0.1, 0.1));
        moons[i].color( Color.GRAY );
    }

    fun PlanetSys( float dist)
    {
        dist => distance;
    }

    fun void latest( float mag)
    {
        mag/2 => float scaled;
        moons[playhead].sca(@(scaled, scaled, scaled));
        playhead++;
        NUM_MOONS %=> playhead;

    }

    fun void update( float dt )
    {
        playhead => int pos;
        for( int i; i < moons.size(); i++ )
        {
            pos--; if( pos < 0 ) NUM_MOONS-1 => pos;
            moons[pos].posX(distance + i*MOON_INTERVAL + .1);
        }
    }
}


// Frequency Planet Systems and Planets represented by each sphere 
GGen sunSystem;

PlanetSys oneSys(1.5);
PlanetSys twoSys(2.0);
PlanetSys threeSys(2.5);
PlanetSys fourSys(3.0);
PlanetSys fiveSys(3.5);
PlanetSys sixSys(4.0);
PlanetSys sevenSys(4.5);
PlanetSys eightSys(5.0);

GSphere sun, one, two, three, four, five, six, seven, eight;

[one, two, three, four, five, six, seven, eight] @=> GSphere planets[];

// BeepLine is the axis of the sun
GLines beepLine --> GG.scene();
beepLine.width(.03);
beepLine.color(Color.WHITE);
[ @(0.0, 3.0), @(0.0, -3.0) ] @=> vec2 linePoints[];
beepLine.positions( linePoints );



// orbit camera
GOrbitCamera cam => GG.scene().camera;

// waveform renderer
GLines waveform --> GG.scene(); 
waveform.width(.01);
waveform.posY(WAVEFORM_Y);
// color0
waveform.color( Color.WHITE );

// Settings for the audio components

adc => Flip accum => blackhole;
adc => PoleZero dcbloke => FFT fft => blackhole;
=.95 => dcbloke.blockZero;
WINDOW_SIZE => accum.size;
Windowing.hann(WINDOW_SIZE) => fft.window;
WINDOW_SIZE*2 => fft.size;
Windowing.hann(WINDOW_SIZE) @=> float window[];

float samples[0];
complex response[0];
vec2 positions[WINDOW_SIZE];
// Band boundary indices for 1024 frequency bins split based on human hearing critical bands 
[
    [0, 7],     
    [8, 21],    
    [22, 47],   
    [48, 92],   
    [93, 173], 
    [174, 316], 
    [317, 571], 
    [572, 1024] 
] @=> int bandBins[][];

// Settings for the graphical components

for( auto x : [ sun, one, two, three, four, five, six, seven, eight] )
    x.mat().wireframe(true);
GG.scene().ambient(@(.5,.5,.5));

// set color for each planet
sun.color( Color.GOLD );
one.color(Color.RED);
two.color(Color.ORANGE);
three.color(Color.YELLOW);
four.color(Color.GREEN);
five.color(Color.CYAN);
six.color(Color.BLUE);
seven.color(Color.DARKPURPLE);
eight.color(Color.PINK);

//Set position for each planet system
oneSys.pos(@(0.0, 0.0, 0.0));
twoSys.pos(@(0.0, 0.0, 0.0));
threeSys.pos(@(0.0, 0.0, 0.0));
fourSys.pos(@(0.0, 0.0, 0.0));
fiveSys.pos(@(0.0, 0.0, 0.0));
sixSys.pos(@(0.0, 0.0, 0.0));
sevenSys.pos(@(0.0, 0.0, 0.0));
eightSys.pos(@(0.0, 0.0, 0.0));

// position of each planet's orbit 
one.pos(@(1.5, 0.0, 0.0));
two.pos(@(2.0, 0.0, 0.0));
three.pos(@(2.5, 0.0, 0.0));
four.pos(@(3.0, 0.0, 0.0));
five.pos(@(3.5, 0.0, 0.0));
six.pos(@(4.0, 0.0, 0.0));
seven.pos(@(4.5, 0.0, 0.0));
eight.pos(@(5.0, 0.0, 0.0));


// initial scaling of each planet
sun.sca(@(1.0, 1.0, 1.0));
one.sca(@(0.4, 0.4, 0.4));
two.sca(@(0.4, 0.4, 0.4));
three.sca(@(0.4, 0.4, 0.4));
four.sca(@(0.4, 0.4, 0.4));
five.sca(@(0.4, 0.4, 0.4));
six.sca(@(0.4, 0.4, 0.4));
seven.sca(@(0.4, 0.4, 0.4));
eight.sca(@(0.4, 0.4, 0.4));



// construct scenegraph - add each planet system to the solar system
oneSys --> sunSystem --> GG.scene();
twoSys --> sunSystem;
threeSys --> sunSystem;
fourSys --> sunSystem;
fiveSys --> sunSystem;
sixSys --> sunSystem;
sevenSys --> sunSystem;
eightSys --> sunSystem;

// add planet to the respective planet system
sun --> sunSystem;
one --> oneSys;
two --> twoSys;
three --> threeSys;
four --> fourSys;
five --> fiveSys;
six --> sixSys;
seven --> sevenSys;
eight --> eightSys;

// position camera
cam.pos( @(0, 5, 7) ); 
cam.lookAt( @(0, 0, 0) );

// map audio buffer to 3D positions
fun void map2waveform( float in[], vec2 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2waveform()", "" >>>;
        return;
    }
    
=    DISPLAY_WIDTH => float width;
    for (int i; i < in.size(); i++)
    {
        -width/2 + width/WINDOW_SIZE*i => out[i].x;
        in[i] * 2 * window[i] => out[i].y;
    }
}

// sum the total acoustic energy in the range of bins specified in indices
fun float combineBins(complex in[], int indices[] )
{
    0.0 => float totalEnergy;
    
    for (indices[0] => int i; i < indices[1]; i++)
    {
        Math.sqrt( (in[i]$polar).mag ) => float magnitude;
        magnitude +=> totalEnergy;
    }

    return totalEnergy;

}

// map planet settings based on spectrum
fun void map2planets (complex responses[])
{
     float binEnergies[8];

    // call combine bins and submit each range of indices specified in bandBins array to result in the total acoustic energy of eight bins
    for (0=> int i; i < 8; i++)
    {
        combineBins(responses, bandBins[i]) => binEnergies[i];
    }

    // set planet size to amplitude of the frequency bin
    one.sca(@(binEnergies[0], binEnergies[0], binEnergies[0]));
    two.sca(@(binEnergies[1], binEnergies[1], binEnergies[1]));
    three.sca(@(binEnergies[2], binEnergies[2], binEnergies[2]));
    four.sca(@(binEnergies[3], binEnergies[3], binEnergies[3]));
    five.sca(@(binEnergies[4], binEnergies[4], binEnergies[4]));
    six.sca(@(binEnergies[5], binEnergies[5], binEnergies[5]));
    seven.sca(@(binEnergies[6], binEnergies[6], binEnergies[6]));
    eight.sca(@(binEnergies[7], binEnergies[7], binEnergies[7]));
    
    // rotate systems
	sunSystem.rotateY(REVOLVE_FACTOR * GG.dt());
	oneSys.rotateY(binEnergies[0]*REVOLVE_FACTOR * GG.dt());
	twoSys.rotateY(binEnergies[1]*REVOLVE_FACTOR * GG.dt());
	threeSys.rotateY(binEnergies[2]*REVOLVE_FACTOR * GG.dt());
	fourSys.rotateY(binEnergies[3]*REVOLVE_FACTOR * GG.dt());
	fiveSys.rotateY(binEnergies[4]*REVOLVE_FACTOR * GG.dt());
	sixSys.rotateY(binEnergies[5]*REVOLVE_FACTOR * GG.dt());
	sevenSys.rotateY(binEnergies[6]*REVOLVE_FACTOR * GG.dt());
	eightSys.rotateY(binEnergies[7]*REVOLVE_FACTOR * GG.dt());

    one.rotateY(REVOLVE_FACTOR * GG.dt());

    oneSys.latest(binEnergies[0]);
    twoSys.latest(binEnergies[1]);
    threeSys.latest(binEnergies[2]);
    fourSys.latest(binEnergies[3]);
    fiveSys.latest(binEnergies[4]);
    sixSys.latest(binEnergies[5]);
    sevenSys.latest(binEnergies[6]);
    eightSys.latest(binEnergies[7]);

    // Toggle music beeps on and off
    if (GWindow.keyDown(GWindow.KEY_SPACE))
    {
        if (0 == playMusic)
        {
            1 => playMusic;
        }
        else
        {
            0 => playMusic;
        }
    }
    if (1 == playMusic)
    {
        playNote(planets);
    }

}

// Determine when to play notes from planet's position in orbit
fun void playNote(GSphere planets[])
{   

    for (0 => int i; i < planets.size(); i++)
    {

        planets[i].posWorld().x => float xpos;
        //<<< xpos >>>;

        prevPosX[i] => float xprev;

        if (xpos/prevPosX[i] < 0)
        {
            <<< "here" >>>;
            spork ~ triggerBeep(i);
            xpos => prevPosX[i];
        }
    }

}

// settings for the beep sound when planets cross certain point in orbit
fun void triggerBeep( int noteIndex )
{
    TriOsc beep => ADSR env => NRev rev => dac;
    0.15 => env.gain;
    env.set( 5::ms, 50::ms, 1, 10::ms );
    rev.mix(.7);

    Std.mtof( notes[noteIndex] + offset ) => beep.freq;

    env.keyOn( 1 );
    BEEP_TIME => now;
    env.keyOff( 1 );
    80::ms => now; // allow release tail to complete
}


// do audio stuff
fun void doAudio()
{
    while( true )
    {
        accum.upchuck();
        accum.output( samples );
        fft.upchuck();
        fft.spectrum( response );
        WINDOW_SIZE::samp/2 => now;
    }
}
spork ~ doAudio();

// graphics render loop
while( true )
{
    GG.nextFrame() => now;
    map2waveform( samples, positions );
    waveform.positions( positions ); // chugl
    map2planets(response);

}