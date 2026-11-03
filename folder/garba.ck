@import "chodash";


// arrays that indicate the movement patterns for dancers in a given ring
[1, 1, 1, 1, -1, -1] @=> int r1_moves[];
[-1, -1, -1, -1, 1, 1] @=> int r2_moves[];
[1, 1, 0] @=> int r3_moves[];


// Dancer class 
class Dancer extends GMesh
{
    9 => int num_slots; 
    0 => int first_pos;
    0 => int curr_pos;
    0 => int next_pos;
    0 => int index;
    int ring_type[];
    Ring ringa;
    int dancer_no;

    fun Dancer(int slots, int fp, int ri, Ring r, int no, string pic)
    {
        no => dancer_no;
        slots => num_slots;
        fp => first_pos;
        fp => curr_pos;

        r @=> ringa;

        this.pos(ringa.pos() + ringa.getPos()[first_pos]);

        if (ri == 1) { r1_moves @=> ring_type;}
        if (ri == 2) { r2_moves @=> ring_type;}
        if (ri == 3) { r3_moves @=> ring_type;}


        // load appropriate image and texture based on the picture given and maintaining the picture's aspect ratio
        TextureLoadDesc load_desc;
        true => load_desc.flip_y;
        true => load_desc.gen_mips;
        Texture.load(me.dir() + pic, load_desc) @=> Texture tex;
        FlatMaterial sprite_material;
        sprite_material.colorMap(tex);
        new PlaneGeometry() => this.geometry;
        sprite_material => this.material;
        (tex.width() $ float) / (tex.height() $ float) => float aspect;
        0.7 => float base_height;
        .5 => float scale_factor;  
        base_height * scale_factor => float final_height;
        this.sca(@(final_height * aspect, final_height, 1.0));
    }  

    fun void move()
    {
        // move dancers based on the movement array displacement 
        (curr_pos + ring_type[index]) % num_slots => next_pos;

        if (next_pos < 0) {num_slots + next_pos => next_pos;}

        this.pos(ringa.pos() + ringa.getPos()[next_pos]);
        ringa.getSlots()[curr_pos].updateDancer(false);

        next_pos => curr_pos;
        ringa.getSlots()[next_pos].updateDancer(true);
        (index + 1) % ring_type.size() => index;
    }
}


// class to move all the dancers together since they all move to the same beat
class Dancers extends GGen
{
    Dancer ppl[];
    
    fun Dancers(Dancer d[])
    {
       d @=> ppl;
    }

    fun void move()
    {
        for (0 => int i; i < ppl.size(); i++) {
            ppl[i].move();
        }
    }
}

// every slot within a ring
class RingSlot extends GCircle
{
    .1 => float _radius;
    
    false => int checked;
    false => int has_dancer;
    int slot;

    fun RingSlot(int slot) {
        slot => this.slot;

        this.sca(.1);
        this.color(Color.WHITE);
    }

    fun vec3 getPos() { return this.pos(); }

    fun void setPos(float x, float y, float z) { this.pos(@(x, y, z));}

    // update color based on whether that particular slot is checked 
    fun void updateColor()
    {
        if (checked)
        {
            @(255 / 255.0, 215 / 255.0, 0 / 255.0) => vec3 brass;
            this.color(brass);
        }
        else {this.color(Color.WHITE);}
    }
    
    // change checked state of a given ring slot
    fun void changeState()
    {   
        if (checked == true) {false => checked;}
        else {true => checked;}

        updateColor();
    }

    //update whether a dancer is present or not in a given ring slot
    fun void updateDancer(int s)
    {
        s => has_dancer;
        if (s == 1 && this.isChecked()){this.sca(.5);}
        else {this.sca(.1);}
    }

    // returns whether spot has been checked
    fun int isChecked() {return checked;}

    // returns whether the spot has a dancer
    fun int hasDancer() {return has_dancer;}
}

public class ClickCommand extends MouseCommand
{
    RingSlot @ slot;

    fun @construct(RingSlot s)
    {
        s @=> this.slot;
    }

    fun void click(MouseTarget target)
    {
        slot.changeState();
    }
}

public class Ring extends GGen
{
    float radius;
    int _N;

    1::second => dur _beatDuration;

    RingSlot slots[];
    SndBuf sounds[];
    vec3 positions[];
    
    MouseTarget itemTargets[];
    ClickCommand clickers[];

    fun Ring(int N, float rad, string sample)
    {   
        rad => radius;
        N => _N;
        new RingSlot[_N] @=> slots;
        new SndBuf[_N] @=> sounds;
        new vec3[_N] @=> positions;

        new MouseTarget[_N] @=> itemTargets;
        new ClickCommand[_N] @=> clickers;
        
        for(0 => int i; i < _N; i++)
        {
            // determine spot of each ring spot by splitting circle into _N slots of theta size pi/_N and radius
            (i $ float / _N) * 2.0 * Math.PI => float angle;
            
            radius * Math.cos(angle) => float x;
            radius * Math.sin(angle) => float y;

            new RingSlot(i) @=> slots[i];

            @(x, y, 0) @=> positions[i];

            slots[i].setPos(x, y, 0);

            sounds[i] => dac;
            sounds[i].read(me.dir() + sample);
            sounds[i].gain(0);

            slots[i] --> this;

            new ClickCommand(slots[i]) @=> clickers[i];
            new MouseTarget(slots[i]) @=> itemTargets[i];

            Mouse.bind(clickers[i], Mouse.LEFT, itemTargets[i]);
        }
    }

    fun vec3[] getPos() {return positions;}
    fun RingSlot[] getSlots() {return slots;}

    // plays appropriate sound based on whether the ring slot is checked AND has a dancer
    fun void play()
    {
        for(0 => int i; i < _N; i++)
        {
            if(slots[i].isChecked() && slots[i].hasDancer())
            {   
                sounds[i].pos(0);
                sounds[i].gain(0.2); // Prevents clipping across multiple active sounds
            }
        }
    }
}

// class for changing drumbeat state based on whether it is clicked on
class DrumBeatClickCommand extends MouseCommand
{
    DrumBeat @ beat;

    fun DrumBeatClickCommand(DrumBeat b) {b @=> beat;}

    fun void click(MouseTarget target) { beat.changeState(); }
}

// class for every individual drum beat in a given bar
class DrumBeat extends GPlane
{
    @(.08, .08) => vec2 _dims;
    false => int checked;

    @(112 / 255.0, 130 / 255.0, 56 / 255.0) => vec3 olive;
    @(255 / 255.0, 215 / 255.0, 0 / 255.0) => vec3 brass;

    fun DrumBeat()
    {
        this.sca(_dims);
        this.color(Color.BLACK);
    }

    // change size and color of a drum beat based on whether it has been clicked on 
    fun void changeState()
    {
        !checked => checked;
        if (checked) {
            this.color(brass);
            this.sca(_dims*1.5);
        } else {
            this.color(Color.BLACK);
            this.sca(_dims);

        }
    }

    fun int isChecked() { return checked;}

    fun void highlight() {this.color(olive);}
    fun void reset()
    {
        if (isChecked()) {this.color(brass);}
        else {this.color(Color.BLACK);}
    }
}

// class for every bar that contains six notes - represented as a brown rectangle representing a different drum

class Bar extends GPlane
{
    @(.85, .18) => vec2 dims;
    @(74 / 255.0, 44 / 255.0, 17 / 255.0) => vec3 brown;
    6 => int _numBeats;
    false => int checked;


    DrumBeat @ beats[_numBeats];
    SndBuf dhols[];

    MouseTarget beatTargets[];
    DrumBeatClickCommand beatClickers[];

    fun Bar()
    {
        this.sca(dims);
        this.color(brown);
        new MouseTarget[_numBeats] @=> beatTargets; 
        new DrumBeatClickCommand[_numBeats] @=> beatClickers; 
        new SndBuf[_numBeats] @=> dhols;

        for(0 => int i; i < _numBeats; i++)
        {
            new DrumBeat @=> beats[i];

            -0.4 + (i * 0.16) => float x;
            beats[i].pos(@(x, 0.0, 0.05));

            dhols[i] => dac;
            dhols[i].read(me.dir() + "/dhol.wav");
            dhols[i].gain(0);

            beats[i] --> this;

            new MouseTarget(beats[i]) @=> beatTargets[i];
            new DrumBeatClickCommand(beats[i]) @=> beatClickers[i];

            Mouse.bind(beatClickers[i], Mouse.LEFT, beatTargets[i]);
        }
    }

    fun SndBuf[] getDhols() { return dhols; }
    fun DrumBeat[] getBeats() { return beats; }
    fun int isChecked() { return false; }
}

// class for all the four bars/drums together
class DholSystem extends GPlane
{
    @(1.2, 3.0) => vec2 dims;
    4 => int _numBars;

    Bar @ bars[_numBars];

    fun DholSystem()
    {
        this.sca(dims);
        this.color(Color.BLACK);

        for(0 => int i; i < _numBars; i++)
        {
            new Bar() @=> bars[i];
            bars[i].pos(@(0, yPos(i), 0.02));
            bars[i] --> this;
        }
    }

    // determine yposition of each bar/drum on the "stage" side
    fun float yPos(int rowPos)
    {
        if (rowPos == 0) return  0.36;
        if (rowPos == 1) return  0.12;
        if (rowPos == 2) return -0.12;
        if (rowPos == 3) return -0.36;
        return 0.0;
    }

    // Step through a specific beat in a specific bar and play sounds when appropriate
    fun DrumBeat playStep(int barIdx, int beatIdx)
    {
        bars[barIdx] @=> Bar thisBar;
        thisBar.getBeats()[beatIdx] @=> DrumBeat thisBeat;
        thisBar.getDhols()[beatIdx] @=> SndBuf thisDhol;

        thisBeat.highlight();
        if(thisBeat.isChecked())
        {
            thisDhol.pos(0);
            thisDhol.gain(0.15); 
        }

        return thisBeat;
    }
}

GG.camera().orthographic();
GG.camera().viewSize(4.0);
TextureLoadDesc load_desc;

// load Goddess Durga picture and keep in center of garba circle
true => load_desc.flip_y;
true => load_desc.gen_mips;
Texture.load(me.dir() + "durga.png", load_desc) @=> Texture tex;
FlatMaterial sprite_material;
sprite_material.colorMap(tex);
GMesh sprite(new PlaneGeometry, sprite_material) --> GG.scene();
sprite.pos(@(.75 , 0.0, 0.1));
(tex.width() $ float) / (tex.height() $ float) => float aspect;
0.7 => float base_height;
sprite.sca(@(base_height * aspect, base_height, 1.0));

// create rings and set positions
Ring ring1(9, .8, "/clap.wav") --> GG.scene();
Ring ring2(16, 1.20, "/ghungroo.wav") --> GG.scene();
Ring ring3(25, 1.60, "/dandiya.wav") --> GG.scene();

ring1.pos(@(.75, 0, 0));
ring2.pos(@(.75, 0, 0));
ring3.pos(@(.75, 0, 0));

// create dancers
Dancer d1(9, 1, 1, ring1, 1, "/RK.png") --> GG.scene();
Dancer d2(9, 4, 1, ring1, 2, "/RK.png") --> GG.scene();
Dancer d3(9, 7, 1, ring1, 3, "/RK.png") --> GG.scene();
Dancer d4(16, 0, 2, ring2, 4, "/garba1.png") --> GG.scene();
Dancer d5(16, 3, 2, ring2, 5, "/garba2.png") --> GG.scene();
Dancer d6(16, 6, 2, ring2, 6, "/garba1.png") --> GG.scene();
Dancer d7(16, 9, 2, ring2, 7, "/garba2.png") --> GG.scene();
Dancer d8(16, 12, 2, ring2, 8, "/garba1.png") --> GG.scene();
Dancer d10(25, 2, 3, ring3, 10, "/garba3.png") --> GG.scene();
Dancer d11(25, 5, 3, ring3, 11, "/garba4.png") --> GG.scene();
Dancer d12(25, 8, 3, ring3, 12, "/garba3.png") --> GG.scene();
Dancer d13(25, 11, 3, ring3, 13, "/garba4.png") --> GG.scene();
Dancer d14(25, 14, 3, ring3, 14, "/garba3.png") --> GG.scene();
Dancer d15(25, 17, 3, ring3, 15, "/garba4.png") --> GG.scene();
Dancer d16(25, 20, 3, ring3, 16, "/garba3.png") --> GG.scene();
Dancer d17(25, 23, 3, ring3, 17,"/garba4.png") --> GG.scene();

// create array of dancers and send to Dancers class
[d1, d2, d3, d4, d5, d6, d7, d8, d10, d11, d12, d13, d14, d15, d16, d17] @=> Dancer dancerArray[];
Dancers dAll(dancerArray) --> GG.scene();

//create dhol system
new DholSystem() @=> DholSystem myDhols;
myDhols --> GG.scene();
myDhols.pos(@(-2.5, 0, 0));

// Unified Master Clock 
fun void master_clock() {
    0 => int total_beats;
    
    while (true) {
        total_beats % 6 => int beat_in_bar;       
        (total_beats / 6) % 4 => int current_bar; 

        // Every 6 beats (1.5 seconds) on beat 0: step dancers & play rings
        if (beat_in_bar == 0) {
            dAll.move();
            ring1.play();
            ring2.play();
            ring3.play();
        }

        // Every beat (0.25 seconds): play active dhol step
        myDhols.playStep(current_bar, beat_in_bar) @=> DrumBeat thisBeat;

        total_beats++;
        0.25::second => now;

        thisBeat.reset();
    }
}

spork ~ master_clock();

// Main gameloop
while(true)
{
    GG.nextFrame() => now;
    Keyboard.update();
    Mouse.update();
}