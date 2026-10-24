// class Dancer extends GGen
// {

// }

@import "chodash";
// @import "../../packages/mouse/index.ck";


class RingSlot extends GGen
{
    GCircle circle --> this;
    .4 => float _radius;
    
    circle.sca(.4);
    circle.color(Color.WHITE);

    false => int checked;
    int slot;


    fun RingSlot(int slot) {
        slot => this.slot;

    }

    fun void setPos(float x, float y, float z)
    {
        // circle.pos(x, y, z);
        this.pos(@(x, y, z));
    }

    fun void showStatus()
    {
        
    }

    fun void updateColor()
    {
        if (checked)
        {
            circle.color(Color.RED);
        }
        else
        {
            circle.color(Color.WHITE);
        }
    }

    fun void changeState()
    {   
        if (checked == true) {false => checked;}
        else {true => checked;}

        updateColor();
        showStatus();
    }

    fun int isChecked()
    {
        return checked;
    }
    // fun void showX()
    // {
    //     //this function puts an x in the circle if isChecked is true, otherwise, nothing
    // }

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
    0.8 => float _radius;
    6 => int _N;

    1.5::second => dur _beatDuration;

    RingSlot slots[_N];
    SndBuf claps[_N];
    
    MouseTarget itemTargets[_N];
    ClickCommand clickers[_N];

    fun Ring(int N)
    {

        N => _N;
        // new RingSlot[_N] @=> slots;
        new SndBuf[_N] @=> claps;
        
        for(int i; i < _N; i++)
        {
            // 1. Calculate an even angle around the circle (in radians)
            (i $ float / _N) * 2.0 * Math.PI => float angle;
            
            // 2. Multiply the trigonometry by the radius to place them along the edge
            _radius * Math.cos(angle) + 1.5 => float x;
            _radius * Math.sin(angle) => float y;

            new RingSlot(i) @=> slots[i];

            // 3. CRITICAL: Push them slightly forward on the Z-axis (e.g., 0.1) 
            // This layers them safely ON TOP of the massive black background fill circle!
            slots[i].setPos(x, y, 0);

            // Set up sound chains
            claps[i] => dac;
            claps[i].read(me.dir() + "/clap.wav");
            claps[i].gain(0);

            // Connect to scene graph
            slots[i] --> GG.scene();

            new ClickCommand(slots[i]) @=> clickers[i];
            // new MouseTarget(slots[i], @(0.8, 0.8), 1) @=> itemTargets[i];
            new MouseTarget(slots[i]) @=> itemTargets[i];

            Mouse.bind(clickers[i], Mouse.LEFT, itemTargets[i]);

            <<< "Bound slot", i >>>;
        }

    }

    // fun float radius(float r)
    // {
    //     r => _radius;

    //     outline.sca(_radius);
    //     fill.sca(_radius * .99);
    // }

    fun void play()
    {
        // once this function is sporked, it moves through each slot at a periodic rate, checks if that slot is "checked", and if so, plays a sound

        while(true)
        {
            for(int i; i < _N; i++)
            {
                if(slots[i].isChecked())
                {
                    claps[i].pos(0);
                    claps[i].gain(1.0);
                }
                else
                {
                    claps[i].gain(0);
                }

                // wait one beat duration
                _beatDuration => now;
            }
        }

    }
}

class DrumBeat extends GGen
{
    GPlane plane --> this;
    @(.25, .25) => vec2 _dims;
    false => int checked;


    fun DrumBeat()
    {
        plane.sca(_dims);
        plane.color(Color.BLUE);
    }

    fun void showStatus()
    {
        
    }

    fun void changeState()
    {
        if (checked)
        {
            false => checked;
        }
        else
        {
            true => checked;
        }

        // Update the beat's color
        if (checked)
        {
            plane.color(Color.GREEN);
        }
        else
        {
            plane.color(Color.BLUE);
        }

        // Show the floating status text
        showStatus();
    }

    fun int isChecked()
    {
        return checked;
    }
}

public class DrumBeatClickCommand extends MouseCommand
{
    DrumBeat @ beat;

    fun @construct(DrumBeat b)
    {
        b @=> beat;
    }

    fun void click(MouseTarget target)
    {
        beat.changeState();
    }
}


class Bar extends GGen
{
    GPlane plane --> this;
    @(1.2, 0.8) => vec2 dims;
    6 => int _numBeats;
    true => int checked;

    DrumBeat beats[_numBeats];
    SndBuf dhols[_numBeats];

    MouseTarget beatTargets[_numBeats];
    DrumBeatClickCommand beatClickers[_numBeats];



    fun Bar()
    {
        plane.sca(dims);
        plane.color(Color.YELLOW);
        new SndBuf[_numBeats] @=> dhols;

        for(int i; i < _numBeats; i++)
        {
            new DrumBeat @=> beats[i];

            i/3 => int row;
            i%3 => int column;

            beats[i].pos(xPos(column), yPos(row), 0.1);

            // Set up sound chains
            dhols[i] => dac;
            dhols[i].read(me.dir() + "/dhol.wav");
            dhols[i].gain(0);

            // Connect to scene graph
            beats[i] --> this;

            new MouseTarget(beats[i], @(0.5, 0.5), 1) @=> beatTargets[i];
            new DrumBeatClickCommand(beats[i]) @=> beatClickers[i];

            Mouse.bind(beatClickers[i], Mouse.LEFT, beatTargets[i]);


        }

    }

    fun SndBuf[] getDhols() { return dhols; }
    fun DrumBeat[] getBeats() { return beats; }

    // Centered layout coordinates local to this bar block
    fun float xPos(int colPos)
    {
        if (colPos == 0) return -0.35;
        if (colPos == 1) return 0.0;
        if (colPos == 2) return 0.35;
        return 0.0;
    }

    fun float yPos(int rowPos)
    {
        if (rowPos == 0) return 0.2;
        if (rowPos == 1) return -0.2;
        return 0.0;
    }

    fun int isChecked() { return checked;}
   
}

class DholSystem extends GGen
{
    GPlane plane --> this;
    @(2, 1.4) => vec2 dims;
    4 => int _numBars;

    .25::second => dur _beatDuration;

    Bar bars[_numBars];

    fun DholSystem()
    {
        plane.sca(dims);
        plane.color(Color.BLACK);

        for(int i; i < _numBars; i++)
        {
            new Bar @=> bars[i];
            i/2 => int row;
            i%2 => int column;


            bars[i].pos(@(xPos(column), yPos(row), 0.1));
            bars[i] --> this;
        }

    }

    fun float xPos(int colPos)
    {
        if (colPos == 0) return -0.7;
        if (colPos == 1) return 0.7;
        return 0.0;
    }

    fun float yPos(int rowPos)
    {
        if (rowPos == 0) return 0.5;
        if (rowPos == 1) return -0.5;
        return 0.0;
    }

    fun void play()
    {
        // once this function is sporked, it moves through each slot at a periodic rate, checks if that slot is "checked", and if so, plays a sound

        while(true)
        {
            for(int i; i < _numBars; i++)
            {
                bars[i] @=> Bar thisBar;
                for(int j; j < 6; j++)
                {
                    thisBar.getBeats()[j] @=> DrumBeat thisBeat;
                    if(thisBeat.isChecked())
                    {
                        thisBar.getDhols()[j].pos(0);
                        thisBar.getDhols()[j].gain(0.05);
                    }
                    else
                    {
                        thisBar.getDhols()[j].gain(0.0);
                    }
                     _beatDuration => now;
                }

                // wait one beat duration
               
            }
        }

    }
}

GG.camera().orthographic();
GG.camera().viewSize(4.0);


TextureLoadDesc load_desc;
true => load_desc.flip_y;  // flip the texture vertically
true => load_desc.gen_mips; // generate mip maps automatically
Texture.load(me.dir() + "durga.jpg", load_desc) @=> Texture tex;
FlatMaterial sprite_material;
sprite_material.colorMap(tex); // texture

GMesh sprite(new PlaneGeometry, sprite_material) --> GG.scene();
sprite.pos(@(1.5, 0.0, 0.1));
sprite.sca(0.7);


Ring myRing(6) --> GG.scene();
DholSystem myDhols() --> GG.scene();

myRing.pos(@(1.2, 0.0, 0.0));

myDhols.pos(@(-1.2, 0.0, 0.0)); 

spork ~ myRing.play();
spork ~ myDhols.play();
//spork ~ drumSeq.play();


//true => slot[5].isChecked;


/// main gameloop
while(true)
{
    GG.nextFrame() => now;
    Keyboard.update();
    Mouse.update();
    // <<< "frame" >>>;
}