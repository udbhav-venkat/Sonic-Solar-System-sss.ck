//-----------------------------------------------------------------------------
// name: sss.ck
// desc: solar system example demoing scenegraph + local vs global transforms
//
// author: Udbhav Venkataraman
// date: Fall 2026
//-----------------------------------------------------------------------------
// scene setup

// window title
GWindow.title( "sonic orbit" );
// uncomment to fullscreen
//GWindow.fullscreen();


// window size
1024 => int WINDOW_SIZE;
// y position of waveform
3 => float WAVEFORM_Y;
// width of waveform and spectrum display
10 => float DISPLAY_WIDTH;
.5 => float REVOLVE_FACTOR;


// Frequency Planet Systems and Planets represented by each sphere 
GGen sunSystem, oneSys, twoSys, threeSys, fourSys, fiveSys, sixSys, sevenSys, eightSys;
GSphere sun, one, two, three, four, five, six, seven, eight;

// orbit camera
GOrbitCamera cam => GG.scene().camera;

// waveform renderer
GLines waveform --> GG.scene(); waveform.width(.01);
// translate up
waveform.posY(WAVEFORM_Y);
// color0
waveform.color( Color.WHITE );

// Settings for the audio components

// accumulate samples from mic
adc => Flip accum => blackhole;
// take the FFT
adc => PoleZero dcbloke => FFT fft => blackhole;
// set DC blocker
.95 => dcbloke.blockZero;
// set size of flip
WINDOW_SIZE => accum.size;
// set window type and size
Windowing.hann(WINDOW_SIZE) => fft.window;
// set FFT size (will automatically zero pad)
WINDOW_SIZE*2 => fft.size;
// get a reference for our window for visual tapering of the waveform
Windowing.hann(WINDOW_SIZE) @=> float window[];

// sample array
float samples[0];
// FFT response
complex response[0];
// vector of positions for the waveform
vec2 positions[WINDOW_SIZE];
// Band boundary indices for 1024 frequency bins split evently into 8 larger bins
[
    [0, 128],     
    [128, 256],    
    [256, 384],   
    [384, 512],   
    [512, 640], 
    [640, 768], 
    [768, 896], 
    [896, 1024] 
] @=> int bandBins[][];


// map audio buffer to 3D positions
fun void map2waveform( float in[], vec2 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2waveform()", "" >>>;
        return;
    }
    
    // mapping to xyz coordinate
    DISPLAY_WIDTH => float width;
    for (int i; i < in.size(); i++)
    {
        // space evenly in X
        -width/2 + width/WINDOW_SIZE*i => out[i].x;
        // map y, using window function to taper the ends
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


// Settings for the graphical components

// set to wireframe
for( auto x : [ sun, one, two, three, four, five, six, seven, eight] )
    x.mat().wireframe(true);

// up the ambient light
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

// position of each planet's orbit 
oneSys.pos(@(1.5, 0.0, 0.0));
twoSys.pos(@(2.0, 0.0, 0.0));
threeSys.pos(@(2.5, 0.0, 0.0));
fourSys.pos(@(3.0, 0.0, 0.0));
fiveSys.pos(@(3.5, 0.0, 0.0));
sixSys.pos(@(4.0, 0.0, 0.0));
sevenSys.pos(@(4.5, 0.0, 0.0));
eightSys.pos(@(5.0, 0.0, 0.0));

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

// do audio stuff
fun void doAudio()
{
    while( true )
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output( samples );
        // upchuck to take FFT, get magnitude response
        fft.upchuck();
        // get spectrum (as complex values)
        fft.spectrum( response );
        // jump by samples
        WINDOW_SIZE::samp/2 => now;
    }
}
spork ~ doAudio();

// graphics render loop
while( true )
{
    // next graphics frame
    GG.nextFrame() => now;
    // map to interleaved format
    map2waveform( samples, positions );
    // set the mesh position
    waveform.positions( positions ); // chugl

    float binEnergies[8];

    // call combine bins and submit each range of indices specified in bandBins array to result in the total acoustic energy of eight bins
    for (0=> int i; i < 8; i++)
    {
        combineBins(response, bandBins[i]) => binEnergies[i];
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
	oneSys.rotateY(REVOLVE_FACTOR * GG.dt());
	twoSys.rotateY(REVOLVE_FACTOR * GG.dt());
	threeSys.rotateY(REVOLVE_FACTOR * GG.dt());
	fourSys.rotateY(REVOLVE_FACTOR * GG.dt());
	fiveSys.rotateY(REVOLVE_FACTOR * GG.dt());
	sixSys.rotateY(REVOLVE_FACTOR * GG.dt());
	sevenSys.rotateY(REVOLVE_FACTOR * GG.dt());
	eightSys.rotateY(REVOLVE_FACTOR * GG.dt());

}