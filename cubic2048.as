package {

	import core3D.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TransformGestureEvent;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.ui.Multitouch;
	import flash.net.SharedObject;
	import flash.net.registerClassAlias;
	import flash.sensors.Accelerometer;
	import flash.events.AccelerometerEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	/*
	import com.sticksports.nativeExtensions.gameCenter.GCAchievement;
	import com.sticksports.nativeExtensions.gameCenter.GCLeaderboard;
	import com.sticksports.nativeExtensions.gameCenter.GCPlayer;
	import com.sticksports.nativeExtensions.gameCenter.GCScore;
	import com.sticksports.nativeExtensions.gameCenter.GameCenter;
	*/
	[SWF(width = "640", height = "960", backgroundColor = "#000000", frameRate = "30")];

	public class cubic2048 extends Sprite
	{
		private static var cubeSize:int=3;

		private var scene:Mesh = null;							//
		private var objM:Mesh = null;							// container holding the cube
		private var frmM:Mesh = null;							// the cube wire frame
		private var numSqrMPs:Vector.<MeshParticles> = null;	// display cube meshParticles
		private var grid:Vector.<ValObj> = null;				// the grid containing the current values

		private var mouseDownPt:Vector3D = null;				// x,y, position & time where mouse is down
		private var mouseDownQ:Vector3D = null;					// orientation at mouse down instance
		private var prevPt:Vector3D = null;						// to do rotation easing
		private var orientQ:Vector3D = new Vector3D(0,0,0,1);	// orientation quaternion
		private var wQ:Vector3D = new Vector3D(0,0,0,1);		// rotation velocity in quaternion
		private var transV:Vector3D = new Vector3D(0,0,0,0);	// translation vector for objM

		private var camPosn:Vector3D = new Vector3D(0,0,7,4);	// fixed position of camera, w=focalL
		private var lightOffset:Vector3D = new Vector3D(0,0,0);
		private var accelMeterV:Point = new Point(0,0);			// accelerometer readings

		private var axisVs:Vector.<Vector3D> = Vector.<Vector3D>([new Vector3D(1,0,0),new Vector3D(0,1,0),new Vector3D(0,0,1)]);	// for swipe dir calculations

		private var sndSlide:Sound = null;
		private var sndMerge:Sound = null;
		private var sndError:Sound = null;
		private var sndWelcome:Sound = null;
		private var colorsBmd:BitmapData = null;				// source color Bitmap
		private var normBmd:BitmapData = null;					// source normalmap
		private var cubesDiff:BitmapData = null;				// unified cubes texture map
		private var cubesNorm:BitmapData = null;				// unified cubes normal map

		private var uiObj:Object = null;

		private var so:SharedObject=null;
		private var userState:SaveState=null;					//
		private var gameEnabled:Boolean=false;					// whether game is playing
		private var bgGlow:Vector3D = new Vector3D(0,0,0,1);	// for that bg pulse

		private var stepFn:Function=null;						// additional function to exec every frame

		public function cubic2048():void
		{
			var delay:int=5;
			function delayHandler(ev:Event):void
			{
				delay--;
				if (delay<=0)
				{
					stage.removeEventListener(Event.ENTER_FRAME,delayHandler);
					init();
				}
			}
			stage.addEventListener(Event.ENTER_FRAME,delayHandler);
		}//endconstr

		/**
		 * initialization
		 */
		public function init():void
		{
			stage.scaleMode = "noScale";
			stage.align = "topLeft";
			scene = new Mesh();
			objM = new Mesh();
			scene.addChild(objM);

			numSqrMPs = new Vector.<MeshParticles>();	// list of batch randered number cubes

			normBmd = new NormCube();					// init textures
			var cs:Sprite = new ColorsStrip();
			colorsBmd = new BitmapData(cs.width,cs.height,false,0xFFFFFFFF);
			colorsBmd.draw(cs);

			sndSlide = new SndSlide();					// init soundfx
			sndMerge = new SndMerge();
			sndError = new SndError();
			sndWelcome = new SndWelcome();

			// ----- restore user state from saved data
			registerClassAlias("SaveStateAlias", SaveState);
			so = SharedObject.getLocal("Cubic2048");
			userState = (SaveState)(so.data.state);
			if (userState==null) userState=new SaveState();

			// ----- do game center initialization
		//	GameCenter.init();
		//	if (GameCenter.isSupported)	GameCenter.authenticateLocalPlayer();

			// ----- init inAppPurchase
			InAppStore.init();

			// ----- bind user UI event listeners
			stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
			stage.addEventListener(Event.ENTER_FRAME,mainStep);
			if(Multitouch.supportsGestureEvents)
				stage.addEventListener(TransformGestureEvent.GESTURE_ROTATE,onGestureRotate);
			var accl:Accelerometer = new Accelerometer();
			if (Accelerometer.isSupported)
				accl.addEventListener(AccelerometerEvent.UPDATE, onAccelUpdate);


			showMainPage();

			var fps:DisplayObject = Mesh.createFPSReadout();
			fps.y = -4;
			addChild(fps);

	//		BannerAd.init(stage.stageWidth,stage.stageHeight);
	//		BannerAd.showAd();
			mainStep();
		}//endconstr

		/**
		 * main menu page with options
		 * @return
		 */
		private function showMainPage():Sprite
		{
			reset(3);						// resets state

			var sw:Number = stage.stageWidth;
			var sh:Number = stage.stageHeight;

			var logoCube:Mesh = createLogoCube();
			objM.addChild(logoCube);		// create logo
			if (Mesh.context3d==null)	Mesh.renderBranch(stage,logoCube,false,"backBuffer");


			var s:Sprite = new Sprite();
			var mode:int=-1;
			stepFn = function():void	// specify to do these at every frame
			{
				if (mode!=-1)
				{
					transV.w*=0.9;					// to 0
					if (s.parent!=null) s.parent.removeChild(s);
				}
				else transV.w = (transV.w*9+1)/10;	// to 1

				if (transV.w<0.95)
				{	// ----- restore orientation
					orientQ.scaleBy(0.9);
					orientQ.w = Math.sqrt(1-orientQ.length*orientQ.length);
				}

				for (var i:int=logoCube.childMeshes.length-1; i>-1; i--)
				{	// ----- shrink/grow logo cubes
					var cc:Mesh = logoCube.childMeshes[i];
					cc.transform.aa = transV.w;
					cc.transform.bb = transV.w;
					cc.transform.cc = transV.w;
				}

				if (transV.w<0.01)
				{
					transV.x=0;
					transV.y=0;
					transV.z=0;
					objM.removeChild(logoCube);
					stepFn = null;
				}
				else
				{
					transV.x=0;
					transV.y= transV.w*1.5;	// shift cube backwards
					transV.z=-transV.w*6;
				}
			}//endfunction
			stepFn();

			var btn:Sprite = createTxtBtn("[START GAME]",function():void	{mode=3; startGame(mode);});	// trick to pre place cubes within
			btn.x = (sw-btn.width)/2;
			btn.y = sh*0.6-btn.height/2;
			s.addChild(btn);
			/*
			btn = createTxtBtn("[PLAY 4x4x4]",function():void	{mode=4;});
			btn.x = (sw-btn.width)/2;
			btn.y = sh*0.8-btn.height/2;
			s.addChild(btn);
			*/
			btn = createTxtBtn("[INSTRUCTIONS]", function():void
			{
				var instrs:String = "<font size='23'>" +
									"The objective of the game is to get the\n" +
									"number 2048 by additions of the number\n" +
									"two and its multiples.\n\n" +
									"Fast swipe up or down, left or right,\n" +
									"to try to join two equal numbers.\n\n" +
									"Rotate the cube by sliding your finger\n" +
									"across the screen, you can use rotate\n" +
									"gesture to tilt the cube as well.</font>";
				var pBtns:Array = [];
				for (var i:int=0; i<s.numChildren; i++)
				{
					s.getChildAt(i).visible = false;
					pBtns.push(s.getChildAt(i));
				}
				var btn:Sprite = createTxtBtn(instrs, function():void
				{
					for (var i:int=0; i<pBtns.length; i++)
					pBtns[i].visible = true;
					btn.parent.removeChild(btn);
				});
				btn.x = (sw-btn.width)/2;
				btn.y = sh*0.55;
				s.addChild(btn);
			});
			btn.x = (sw-btn.width)/2;
			btn.y = sh*0.7-btn.height/2;
			s.addChild(btn);

			btn = createTxtBtn("[HIGH SCORES]", function():void
			{
				try {
	//				GameCenter.showStandardLeaderboard();
				} catch (e:Error) {}
			});
			btn.x = (sw-btn.width)/2;
			btn.y = sh*0.8-btn.height/2;
			s.addChild(btn);

			addChild(s);

			sndWelcome.play(0, 1, new SoundTransform(1, 0));

			return s;
		}//endfunction

		/**
		 * resets game, init according to size
		 */
		private function reset(size:int=3):void
		{
			if (cubeSize!=size || frmM==null)
			{
				if (frmM!=null) objM.removeChild(frmM);
				frmM = createCubeFrame(size);
				objM.addChild(frmM);
			}
			if (uiObj!=null)
			{
				if (uiObj.uiSpr.parent!=null) uiObj.uiSpr.parent.removeChild(uiObj.uiSpr);
				uiObj = null;
			}
			cubeSize = size;
			so.flush();
			gameEnabled = false;

			grid = new Vector.<ValObj>();
			var n:int = cubeSize*cubeSize*cubeSize;
			for (var i:int=0; i<n; i++)
				grid.push(null);
		}//endfunction

		/**
		 * enable game
		 */
		private function startGame(size:int=3):void
		{
			reset(size);
			userState.lastScore=userState.curScore;		// record down last score
			userState.curScore=0; 						// reset score
			userState.numUndos=Math.max(3,userState.numUndos);		//
			userState.history = new Vector.<String>();	// clear off previous step history

			for (var i:int=(size-2)*4; i>-1; i--)
				randomAdd();						// random add 4 or 8 cubes
			gameEnabled=true;
		}//endfunction

		/**
		 * creates the frame guide where the cube positions will be
		 */
		private function createCubeFrame(cubeSize:int):Mesh
		{
			//var bmd:BitmapData = new BitmapData(1,1,false,0x334455);
			var bmd:BitmapData = new BitmapData(1,1,false,0x33FF99);
			var i:int=0;
			var j:int=0;

			var frm:Mesh = new Mesh();
			for (i=cubeSize; i>-1; i--)
				for (j=cubeSize; j>-1; j--)
				{
					var l:Mesh = null;
					l = Mesh.createCube(0.01,0.01,cubeSize,bmd,false);
					l.transform = new Matrix4x4().translate(i-cubeSize/2,j-cubeSize/2,0);
					frm.addChild(l);
					l = Mesh.createCube(0.01,cubeSize,0.01,bmd,false);
					l.transform = new Matrix4x4().translate(i-cubeSize/2,0,j-cubeSize/2);
					frm.addChild(l);
					l = Mesh.createCube(cubeSize,0.01,0.01,bmd,false);
					l.transform = new Matrix4x4().translate(0,i-cubeSize/2,j-cubeSize/2);
					frm.addChild(l);
				}
			frm = frm.mergeTree();
			frm.setLightingParameters(1,1,1,1,1,false,true);
			frm.material.setBlendMode("add");

			/*
			var bmd2:BitmapData = new BitmapData(1,1,false,0x33FF99);
			var dotsLine:Mesh = new Mesh();
			for (i=cubeSize-1; i>-1; i--)
			{
				var dot:Mesh = Mesh.createCube(0.012,0.012,0.5,bmd2);
				dot.transform = new Matrix4x4().translate(0,0,-(cubeSize-1)/2+i);
				dotsLine.addChild(dot);
			}
			dotsLine = dotsLine.mergeTree();
			var dots:Mesh = new Mesh();
			for (i=cubeSize; i>-1; i--)
				for (j=cubeSize; j>-1; j--)
				{
					l = dotsLine.clone();
					l.transform = new Matrix4x4().translate(i-cubeSize/2,j-cubeSize/2,0);
					dots.addChild(l);
					l = dotsLine.clone();
					l.transform = new Matrix4x4().rotX(Math.PI/2).translate(i-cubeSize/2,0,j-cubeSize/2);
					dots.addChild(l);
					l = dotsLine.clone();
					l.transform = new Matrix4x4().rotY(Math.PI/2).translate(0,i-cubeSize/2,j-cubeSize/2);
					dots.addChild(l);
				}
			dots = dots.mergeTree();
			dots.enableLighting(false);
			dots.setAmbient(1,1,1);
			dots.setBlendMode("add");
			frm.addChild(dots);
			*/
			return frm;
		}//

		/**
		 * creates a 3x3x3 cube with letters CUBIC2048 on it
		 */
		private function createLogoCube():Mesh
		{
			// ----- create the texture and normap map
			var A:Array = [	"C","U","B",
							"2","0","I",
							"4","8","C"];
			var C:Array = [	0.4,0.45,0.5,
							0.89,0.86,0.45,
							0.92,0.95,0.4];
			var bmd:BitmapData = new BitmapData(512,512,false,0xFFFFFF);
			var tfmc:Sprite = new TFMC();
			var tf:TextField = (TextField)(tfmc.getChildAt(0));
			tf.autoSize = "left";
			tf.wordWrap = false;
			tf.text = Math.pow(2,i)+"";
			for (var i:int=0; i<9; i++)
			{
				tf.htmlText = "<font size='110'>"+A[i]+"</font>";
				bmd.fillRect(new Rectangle(i%3*512/3,int(i/3)*512/3,512/3,512/3),colorsBmd.getPixel32(colorsBmd.width*C[i],0));
				bmd.draw(tf,new Matrix(1,0,0,1,i%3*512/3+512/6-tfmc.width/2,int(i/3)*512/3+512/6-tfmc.height/2));
			}
			var norm:BitmapData = new BitmapData(512,512,false,0xFFFFFF);
			norm.draw(normBmd,new Matrix(4/3,0,0,4/3));

			// ----- create the logo cubes
			var I:Array = [	0,1,2,3,4,5,6,7,8,	// front layer
							1,4,1,4,7,4,7,4,7,	// middle layer
							2,1,0,5,4,3,8,7,6];	// last layer
			var logo:Mesh = new Mesh();
			for (i=0; i<27; i++)
			{
				var cu:Mesh = Mesh.createCube(0.7,0.7,0.7,bmd,false);
				for (var v:int=cu.vertData.length-11; v>-1; v-=11)
				{
					cu.vertData[v+9] = cu.vertData[v+9]/3+(I[i]%3)/3;		// u
					cu.vertData[v+10] = cu.vertData[v+10]/3+int(I[i]/3)/3;	// v
				}
				cu.setGeometry(cu.vertData,cu.idxsData,true);	// ensures update to 3D vertex buffer
				cu.material.setSpecular(1);
				cu.material.setSpecMap(bmd);
				cu.material.setNormMap(norm);
				cu.transform = new Matrix4x4().translate(i%3-1,-int(i/3)%3+1,int(i/9)-1);
				logo.addChild(cu);
			}
			return logo;
		}//endfunction

		/**
		 * random add a new value cube to the grid
		 */
		private function randomAdd():Boolean
		{
			// ----- create randomised index array
			var R:Vector.<uint> = new Vector.<uint>();
			var n:int = cubeSize*cubeSize*cubeSize;
			for (var i:int=0; i<n; i++)
			{
				var idx:int = Math.round(Math.random()*R.length);
				R.splice(idx,0,i);
			}

			for (i=R.length-1; i>-1; i--)
			{
				idx = R[i];
				var x:int = idx%cubeSize;
				var y:int = int(idx/cubeSize)%cubeSize;
				var z:int = int(idx/cubeSize/cubeSize)%cubeSize;
				if (grid[idx]==null)
				{
					grid[idx]=new ValObj(1+Math.round(Math.random()*2.49),x,y,z,0);
					return true;
				}
			}
			return false;
		}//endfunction

		/**
		 * handles the sliding operation logic
		 * @param	axis	0,1,2  corresponding to x,y,z
		 * @param	right	true,false, left/right directi
		 */
		private function slide(axis:int,right:Boolean):int
		{
			//prn("slide("+axis+","+right+")");
			var slided:Boolean = false;
			var highest:int=0;

			var n:int = grid.length;
			var idx:int=0;
			var dir:int=1;
			if (!right)
			{
				idx=n-1;
				dir=-1;
			}

			for (; idx>-1 && idx<n; idx+=dir)
			{
				var o:ValObj = grid[idx];
				if (o!=null)
				{
					o.ttl--;
					var stride:int = Math.pow(cubeSize,axis);
					var t:ValObj = null;	// target valObj down the line

					// ----- find nearest occupied or edge
					var ow:int=int(idx/stride)%cubeSize;
					var w:int=ow;
					while (t==null)
					{
						w-= dir;
						if (w<0 || w>cubeSize-1)
						{
							w+= dir;
							break;
						}
						t = grid[idx+(w-ow)*stride];
					}
					var nidx:int = idx+(w-ow)*stride;
					//prn("idx->("+idx%4+","+int(idx/4)%4+","+int(idx/16)+")   nidx->("+nidx%4+","+int(nidx/4)%4+","+int(nidx/16)+")");

					if (t!=null && t.val==o.val && t.ttl<int.MAX_VALUE)
					{
						//prn("if !!! w="+w+"  o="+o+"  t="+t);
						slided = true;
						t.val++;
						t.ttl=int.MAX_VALUE;
						if (highest<t.val) highest=t.val;	// current maxval
						userState.curScore += Math.pow(2,t.val);			// increment score
						t.sc = 2;				// set to pop up from position
						grid[idx] = null;			// remove o
						sndMerge.play(0, 1, new SoundTransform(0.5, 0));
						var c:uint = colorsBmd.getPixel32(Math.min(1,t.val/12)*colorsBmd.width,0);
						bgGlow.z += (c%256)/256*t.val/48;
						c = c>>8;
						bgGlow.y += (c%256)/256*t.val/48;
						c = c>>8;
						bgGlow.x += (c%256)/256*t.val/48;

					}
					else
					{
						//if (t!=null) prn("else !!! w="+w+"  o="+o+"  t="+t);
						if (t!=null) w+=dir;			// back up 1 posn
						nidx = idx+(w-ow)*stride;
						if (nidx!=idx)
						{
							grid[idx]=null;							// remove o from old position
							o.tpx = nidx%cubeSize;					// set target point to slide to
							o.tpy = int(nidx/cubeSize)%cubeSize;	// set target point to slide to
							o.tpz = int(nidx/(cubeSize*cubeSize));	// set target point to slide to
							grid[nidx]=o;				// set o in new position
							slided = true;
						}

					}
				}//endif o!=null
			}//endfor z

			if (slided)
			{
				sndSlide.play(0,1,new SoundTransform(1,0));
				return highest;
			}
			else
			{
				sndError.play(0,1,new SoundTransform(1,0));
				return -1;
			}
		}//endfunction

		/**
		 * chk for game over condition: no more moves.
		 */
		private function isGameOver():Boolean
		{
			// ----- chk for empty slots
			for (var i:int=cubeSize*cubeSize*cubeSize-1; i>-1; i--)
			{
				if (grid[i]==null) return false;	// has empty slot
			}
			// ----- chk for adj same values
			for (i=cubeSize*cubeSize*cubeSize-1; i>-1; i--)
			{
				var o:ValObj = grid[i];
				var x:int=i%cubeSize;
				var y:int=int(i/cubeSize)%cubeSize;
				var z:int=int(i/(cubeSize*cubeSize));
				x-=1; 				var idx:int = x+y*cubeSize+z*cubeSize*cubeSize;
				if (x>-1 && grid[idx].val==o.val) return false;
				x+=2;				idx = x+y*cubeSize+z*cubeSize*cubeSize;
				if (x<cubeSize && grid[idx].val==o.val) return false;
				y-=1; x-=1;			idx = x+y*cubeSize+z*cubeSize*cubeSize;
				if (y>-1 && grid[idx].val==o.val) return false;
				y+=2;				idx = x+y*cubeSize+z*cubeSize*cubeSize;
				if (y<cubeSize && grid[idx].val==o.val) return false;
				z-=1; y-=1;			idx = x+y*cubeSize+z*cubeSize*cubeSize;
				if (z>-1 && grid[idx].val==o.val) return false;
				z+=2;				idx = x+y*cubeSize+z*cubeSize*cubeSize;
				if (z<cubeSize && grid[idx].val==o.val) return false;
			}

			return true;
		}//endfunction

		/**
		 * trying to add the matrix effect
		 */
		private var RainM:Vector.<ParticlesEmitter> = null;
		private var RainP:Vector.<Vector3D> = null;
		private function updateMatrixRain():void
		{
			if (RainM==null)
			{
				RainM = new Vector.<ParticlesEmitter>();
				var Bmds:Array = [charFadeSpriteSheet("2",4),charFadeSpriteSheet("0",4),charFadeSpriteSheet("4",4),charFadeSpriteSheet("8",4)]
				for (var i:int=0; i<4; i++)
				{
					var mp:ParticlesEmitter = new ParticlesEmitter(Bmds[i],16,0.3);
					mp.skin.material.setAmbient(0,0.6,0.8);
					RainM.push(mp);
					scene.addChild(mp.skin);
				}
				RainP = new Vector.<Vector3D>();
				for (i=0; i<60; i++)
					RainP.push(new Vector3D(i/59 , ((i+int(Math.random()*60))%60)/59 , 0 , int(Math.random()*4)));
			}


			for (i=RainP.length-1; i>-1; i--)
			{
				var pt:Vector3D = RainP[i];
				if (Math.random()<0.4)
				{
					pt.y-=1/60;
					if (pt.y<0) pt.y+=1;
					pt.w = (pt.w+1)%4;
					var px:Number = pt.x-0.5;				// pre posn x
					var py:Number = pt.y-0.5;				// pre posn y
					var f:Number = camPosn.z/camPosn.w*4;	// mul factor
					RainM[pt.w].emit(px*f,py*f*stage.stageHeight/stage.stageWidth,-camPosn.w*2);
				}
			}
			for (i=RainM.length-1; i>-1; i--)
				RainM[i].update(camPosn.x,camPosn.y,camPosn.z);
		}//endfunction

		/**
		 * update the 3d to reflect the current state of the grid
		 */
		private var maxPow2:int=0;
		private function update3DCubes(grid:Vector.<ValObj>):void
		{
			// ----- chk for and create non existing numbered cube meshes ---------------
			for (var i:int=numSqrMPs.length; i<=maxPow2; i++)
			{
				if (cubesDiff==null)	cubesDiff = new BitmapData(512,512,false,0x00000000);
				if (cubesNorm==null)	cubesNorm = new BitmapData(512,512,false,0x00000000);

				var nSc:Number = Math.min(4,int((i-1)/3)+1)/4;

				// ----- generate texture for cube
				var bmd:BitmapData = new BitmapData(128, 128, false, colorsBmd.getPixel32(Math.min(1,i/12)*colorsBmd.width,0));
				var tfmc:Sprite = new TFMC();
				var tf:TextField = (TextField)(tfmc.getChildAt(0));
				tf.autoSize = "left";
				tf.wordWrap = false;
				tf.text = Math.pow(2,i)+"";
				var sc:Number = Math.min(bmd.width/tfmc.width,bmd.height/tfmc.height);
				bmd.draw(tfmc, new Matrix(sc, 0, 0, sc, (bmd.width - tf.width*sc)/2, (bmd.height - tf.height*sc)/2));
				cubesDiff.draw(bmd,new Matrix(1,0,0,1,(i%4)*128,int(i/4)*128));		// draw to shared bmd

				// ----- generate normal map for cube
				var norm:BitmapData = new BitmapData(bmd.width, bmd.height, false, 0x00000000);
				norm.draw(normBmd,new Matrix(bmd.width/(normBmd.width*nSc),0,0,bmd.height/(normBmd.height*nSc),0,0));
				cubesNorm.draw(norm,new Matrix(1,0,0,1,(i%4)*128,int(i/4)*128));	// draw to shared bmd

				// ----- create cube with modified UV coords
				var cu:Mesh = Mesh.createCube(0.4+nSc*0.2, 0.4+nSc*0.2, 0.4+nSc*0.2, cubesDiff, false);
				for (var v:int=cu.vertData.length-11; v>-1; v-=11)
				{
					cu.vertData[v+9] = cu.vertData[v+9]/4+(i%4)/4;		// u
					cu.vertData[v+10] = cu.vertData[v+10]/4+int(i/4)/4;	// v
				}
				cu.setGeometry(cu.vertData,cu.idxsData,true);	// ensures update to 3D vertex buffer
				var mp:MeshParticles = new MeshParticles(cu);
				mp.skin.material.setSpecular(1);
				mp.skin.material.setAmbient(1,1,1);
				mp.skin.material.setTexMap(cubesDiff);		//
				mp.skin.material.setNormMap(cubesNorm);		//
				mp.skin.material.setSpecMap(cubesDiff);		// use texture as specular map so letters can be seen in high reflection
				//mp.skin.setBlendMode("add");
				//mp.skin.depthWrite = false;
				objM.addChild(mp.skin);
				numSqrMPs.push(mp);
			}
			//prn("maxPow2="+maxPow2+"   numSqrMPs:"+numSqrMPs.length);

			// ----- clear all cubes ----------------------------------------------------
			for (i=numSqrMPs.length-1; i>-1; i--)
				numSqrMPs[i].reset();

			// ----- place cubes --------------------------------------------------------
			if (grid!=null)
			{
			var n:int = grid.length;
			var offset:Number = (cubeSize-1)/2;
			for (var z:int=0; z<n; z++)
			{
				var o:ValObj = grid[z];
				if (o!=null)
				{
					var id:int = o.val;
					if (maxPow2<id) maxPow2 = id;
					if (id>numSqrMPs.length-1) id=numSqrMPs.length-1;
					var dv:Vector3D = new Vector3D(o.tpx-o.px,o.tpy-o.py,o.tpz-o.pz,o.tsc-o.sc);
					if (dv.length>0.2) dv.scaleBy(0.2/dv.length);
					o.px+=dv.x;
					o.py+=dv.y;
					o.pz+=dv.z;
					if (dv.w>0.1) dv.w=0.1;
					if (dv.w<-0.1) dv.w=-0.1;
					o.sc+=dv.w;
					numSqrMPs[id].nextLocDirScale(o.px-offset,o.py-offset,o.pz-offset, 0,0,1, o.sc);
				}
			}
			}

			for (i=numSqrMPs.length-1; i>-1; i--)
				numSqrMPs[i].update();
		}//endfunction

		/**
		 * main game loop
		 */
		private function mainStep(ev:Event=null):void
		{
			if (stepFn!=null) stepFn();		// exec custom function if exists
			if (gameEnabled) UIStep();		// Hud update
			updateMatrixRain();
			update3DCubes(grid);			// update cubes display

			// ----- increment orientation quaternion with quat vel
			orientQ = quatMult(wQ.x,wQ.y,wQ.z,wQ.w, orientQ.x,orientQ.y,orientQ.z,orientQ.w);
			objM.transform = Matrix4x4.quaternionToMatrix(orientQ.w,orientQ.x,orientQ.y,orientQ.z).translate(transV.x,transV.y,transV.z);
			if (cubeSize>3)	// scale down cube so it fits screen for size 4 and above
				objM.transform = new Matrix4x4(3/cubeSize,0,0,0, 0,3/cubeSize,0,0, 0,0,3/cubeSize,0).mult(objM.transform);

			// ----- reduce rotation speed by 0.8
			if (wQ.length>0.0001)
			{
				var ang:Number = Math.acos(wQ.w)*2;
				var sinAng_2:Number = Math.sin(ang/2);
				ang*=0.8;
				var nSinAng_2:Number = Math.sin(ang/2);
				wQ.scaleBy(nSinAng_2/sinAng_2);
				wQ.w = Math.cos(ang/2);
			}
			else
			{	// stop rotation
				wQ.x=wQ.y=wQ.z=0; wQ.w=1;
			}

			// ----- enable objM rotation by user dragging
			if (mouseDownPt!=null)
			{
				var dx:Number = (stage.mouseX-prevPt.x)/(stage.stageWidth);
				var dy:Number = (stage.mouseY-prevPt.y)/(stage.stageWidth);
				prevPt.x = stage.mouseX;
				prevPt.y = stage.mouseY;
				var dv:Vector3D = new Vector3D(dx,dy,-1);
				dv.normalize();
				// ----- append rotation vel quaternion
				var rot:Vector3D = new Vector3D(0,0,-1).crossProduct(dv);
				ang = rot.length;
				sinAng_2 = Math.sin(ang/2);
				rot.normalize();
				wQ = quatMult(	sinAng_2*rot.x,sinAng_2*rot.y,sinAng_2*rot.z,Math.cos(ang/2),
								wQ.x,wQ.y,wQ.z,wQ.w);
			}

			// ----- ease background glow
			bgGlow.scaleBy(0.9);
			frmM.material.setAmbient(0.15+Math.min(1,bgGlow.x*4),0.15+Math.min(1,bgGlow.y*4),0.15+Math.min(1,bgGlow.z*4));

			// ----- render!
			lightOffset.x = (lightOffset.x*9+accelMeterV.x*10)/10;
			lightOffset.y = (lightOffset.y*9+accelMeterV.y*10)/10;
			Mesh.setPointLighting(Vector.<Number>([camPosn.x+lightOffset.x,camPosn.y+lightOffset.y,camPosn.z,1,1,1]));
			Mesh.setCamera(	camPosn.x,camPosn.y,camPosn.z,0,0,0,camPosn.w,0.02);	// focalL,zNear
			Mesh.renderBranch(stage, scene, false,"backBuffer",bgGlow);				// shadows off!
		}//endfunction

		/**
		 * update ui show score and num moves
		 */
		private function UIStep():void
		{
			var sw:int = stage.stageWidth;
			var sh:int = stage.stageHeight;
			var uih:int = (sh-sw)/3;
			var tf:TextField = null;

			var uiColor:uint = 0x335577;

			// ----- create scoreboard display if nonexistant
			if (uiObj==null)
			{
				uiObj = new Object();
				uiObj.uiSpr = new Sprite();										// UI sprite

				for (var i:int=0; i<3; i++)
				{
					var panel:Sprite = new TFMC();
					tf = (TextField)(panel.getChildAt(0));
					tf.autoSize = "left";
					tf.wordWrap = false;
					panel.graphics.beginFill(uiColor,1);
					panel.graphics.drawRoundRect(10,10,sw/3-20,uih-20,50,50);
					panel.graphics.drawRoundRect(15,15,sw/3-30,uih-30,45,45);
					panel.graphics.endFill();
					panel.x = i*sw/3;
					uiObj.uiSpr.addChild(panel);
				}

				var ctf:ColorTransform = new ColorTransform();
				ctf.color = uiColor;

				var btnExit:Sprite = new IcoExit();
				btnExit.buttonMode = true;
				btnExit.x = 10;
				btnExit.y = panel.height+10;
				btnExit.transform.colorTransform=ctf;
				uiObj.uiSpr.addChild(btnExit);
				uiObj.btnExit = btnExit;

				var btnUndo:Sprite = new IcoUndo();
				btnUndo.buttonMode = true;
				btnUndo.y = panel.height+10;
				btnUndo.x = sw-btnUndo.width-10;
				btnUndo.transform.colorTransform=ctf;
				uiObj.uiSpr.addChild(btnUndo);
				uiObj.btnUndo = btnUndo;

				var btnHelp:Sprite = new IcoHelp();
				btnHelp.buttonMode = true;
				btnHelp.y = panel.height+10;
				btnHelp.x = sw/2-btnUndo.width/2;
				btnHelp.transform.colorTransform=ctf;
				uiObj.uiSpr.addChild(btnHelp);
				uiObj.btnHelp = btnHelp;

				addChild(uiObj.uiSpr);
			}

			// ----- update scoreboard display
			if (uiObj.curMax==null || uiObj.curMax<=userState.curMax ||
				uiObj.curScore!=userState.curScore ||
				uiObj.bestScore!=userState.bestScore)
			{
				uiObj.curMax=Math.max(11,userState.curMax+1);
				uiObj.curScore=userState.curScore;
				uiObj.bestScore=userState.bestScore;

				var A:Array =["GOAL",Math.pow(2,uiObj.curMax),"SCORE",userState.curScore,"BEST",userState.bestScore];
				for (i=0; i<3; i++)
				{
					tf = (TextField)((Sprite)(uiObj.uiSpr.getChildAt(i)).getChildAt(0));
					tf.htmlText = "<textformat leading='-15'><font size='28' color='#"+uiColor.toString(16)+"'>"+A[i*2]+"</font>\n<font size='42' color='#"+uiColor.toString(16)+"'>"+A[i*2+1]+"</font></textformat>";
					tf.x = (sw/3-tf.width)/2;
					tf.y = (uih-tf.height)/2;
				}

				// ----- update texture
				var uiBmd:BitmapData = (BitmapData)(uiObj.uiBmd);
				var uiSpr:Sprite = (Sprite)(uiObj.uiSpr);
			}
		}//endfunction

		/**
		 * allows player to rotate with 2 fingers
		 */
		private function onGestureRotate(rotateEvent:TransformGestureEvent):void
		{
			mouseDownPt = null;
			wQ = quatMult( 0,0,Math.sin(rotateEvent.rotation/100),Math.cos(rotateEvent.rotation/100),
								wQ.x,wQ.y,wQ.z,wQ.w);
		}//endfunction

		/**
		 * allows for subtle light shift according to device accelerometer
		 */
		private function onAccelUpdate(ev:AccelerometerEvent):void
		{
			accelMeterV.x = ev.accelerationX;
			accelMeterV.y = ev.accelerationY;
		}//endfunction

		/**
		 * starts drag rotation
		 */
		private function onMouseDown(ev:Event=null):void
		{
			// ----- detect click on btns
			if (uiObj!=null && gameEnabled)
			{
				if (uiObj.btnExit.hitTestPoint(stage.mouseX,stage.mouseY))
				{
					showDarkenNotice("<font size='70'>QUIT GAME?</font>\n\nCURRENT PROGRESS\nWILL BE LOST.",
									showMainPage,true,false,false);
					return;
				}
				if (uiObj.btnHelp.hitTestPoint(stage.mouseX,stage.mouseY))
				{
					showDarkenNotice("<font size='60'>INSTRUCTIONS</font>\n\n<font size='23'>" +
									"The objective of the game is to get the\n" +
									"number 2048 by additions of the number\n" +
									"two and its multiples.\n\n" +
									"Fast swipe up or down, left or right,\n" +
									"to try to join two equal numbers.\n\n" +
									"Rotate the cube by sliding your finger\n" +
									"across the screen, you can use rotate\n" +
									"gesture to tilt the cube as well.</font>",function():void {},false,false,false);
					return;
				}
				if (uiObj.btnUndo.hitTestPoint(stage.mouseX,stage.mouseY) && userState.history.length>0)
				{
					if (userState.numUndos>0)
					showDarkenNotice("<font size='70'>UNDO MOVE?</font>\n\nYOU HAVE "+userState.numUndos+" UNDOS.",
									function():void
									{
										if (userState.numUndos>0)
										{
											restoreState(userState.history.pop());
											userState.numUndos--;
										}
									},true,false,false);
					else
					showDarkenNotice("<font size='70'>NO MORE\nUNDOS LEFT.</font>\n\nWOULD YOU LIKE TO\nPURCHASE MORE UNDOS?",
									function():void
									{
										//stage.addChild(InAppStore.debugTf);
										disableAndDarken(true);
										InAppStore.purchase("com.mingmirage.cubic2048.3undoMoves",function(success:Boolean):void
										{
											if (success)
											{
												userState.numUndos+=3;
												showDarkenNotice("<font size='70'>PURCHASE\nSUCCESSFUL.</font>\n\n3 MORE UNDOS\nHAVE BEEN\nCREDITED.\nTHANK YOU!",function():void {},false,false,false);
											}
											else
											{
												showDarkenNotice("<font size='70'>PURCHASE\nFAILED.</font>\n\n",function():void {},false,false,false);
											}
										});
									},true,false,false);
					return;
				}
			}
			mouseDownPt = new Vector3D(stage.mouseX,stage.mouseY,0,getTimer());
			mouseDownQ = orientQ;
			prevPt = new Vector3D(stage.mouseX,stage.mouseY,0,getTimer());
		}//endfunction

		/**
		 * stops drag rotation and do slide operation
		 */
		private function onMouseUp(ev:Event=null):void
		{
			if (gameEnabled && mouseDownPt!=null && getTimer()-mouseDownPt.w<200)	// if is a fast swipe
			{
				// ----- stop spin
				wQ = new Vector3D(0,0,0,1);		// stop rotation vel

				// ----- find orthogenal vector swipe direction is closest to
				var slideV:Vector3D = new Vector3D(stage.mouseX-mouseDownPt.x,stage.mouseY-mouseDownPt.y,0);
				if (slideV.length>20)
				{
					var aidx:int = 0;
					var maxdp:Number = 0;
					for (var i:int=axisVs.length-1; i>-1; i--)
					{
						var dir:Vector3D = objM.transform.rotateVector(axisVs[i]);
						var dp:Number = dir.dotProduct(slideV);
						if (dp*dp>maxdp*maxdp)
						{
							aidx=i;
							maxdp=dp;
						}
					}
					//prn("aidx="+aidx+" maxdp="+maxdp);

					// ----- write history
					var s:String = "";
					var k:String = "0123456789ABCDEFGHIJKLMNOPQ"
					for (i=grid.length-1; i>-1; i--)
					{
						if (grid[i]==null)	s=k.charAt(0)+s;
						else				s=k.charAt(grid[i].val)+s;
					}
					userState.history.push(s);
					//prn("saveState : "+s);

					// ----- slide in nearest direction
					var highest:int = slide(aidx, maxdp>0);		// returns highest merged value
					if (highest>=0)
						for (i=0; i<cubeSize-2; i++)
							randomAdd();		// randomAdd only if slide successful
	/*
					if (highest==10) 		GameCenter.reportAchievement("com.mingmirage.cubic2048.badge1024",1,true);
					else if (highest==11) 	GameCenter.reportAchievement("com.mingmirage.cubic2048.badge2048",1,true);
					else if (highest==12) 	GameCenter.reportAchievement("com.mingmirage.cubic2048.badge4096",1,true);
					else if (highest==13) 	GameCenter.reportAchievement("com.mingmirage.cubic2048.badge8192",1,true);
		*/
					if (highest>10 && userState.curMax<highest)
					{
						showDarkenNotice("<font size='70'>EXCELLENT!</font>\n\nSCORE\n<font size='60'>"+userState.curScore+"</font>\n\nNOW TRY FOR "+Math.pow(2,highest+1),
									function():void {},false,false,true);
					}
					else if (isGameOver())
					{
						showDarkenNotice("<font size='70'>GAME OVER</font>\n\nNO MORE MOVES\n\nFINAL SCORE\n<font size='60'>"+userState.curScore+"</font>",
									function():void
									{
										/*
										function scoreReportFailed() : void
										{
											GameCenter.localPlayerScoreReported.remove( scoreReportSuccess );
											GameCenter.localPlayerScoreReportFailed.remove( scoreReportFailed );
											showDarkenNotice("UNABLE TO SEND\nSCORE TO GAMECENTER\n\n",function():void {},false,false,false);
										}

										function scoreReportSuccess() : void
										{
											GameCenter.localPlayerScoreReported.remove( scoreReportSuccess );
											GameCenter.localPlayerScoreReportFailed.remove( scoreReportFailed );
										}
										GameCenter.localPlayerScoreReported.add(scoreReportSuccess);
										GameCenter.localPlayerScoreReportFailed.add(scoreReportFailed);
										GameCenter.reportScore("com.mingmirage.cubic2048.highscores",userState.curScore);
										*/
										explodeCube(showMainPage);
									},false,false,true);
					}

					// ----- write userState
					if (userState.curScore>userState.bestScore)		userState.bestScore=userState.curScore;
					if (userState.curMax<highest)					userState.curMax=highest;
					so.data.state = userState;
				}
			}

			mouseDownPt = null;
		}//endfunction

		/**
		 * for that undo function
		 */
		private function restoreState(s:String):void
		{
			var k:String = "0123456789ABCDEFGHIJKLMNOPQ";
			//prn("restoreState("+s+")");
			for (var i:int=s.length-1; i>-1; i--)
			{
				var px:Number = i%cubeSize;
				var py:Number = int(i/cubeSize)%cubeSize;
				var pz:Number = int(i/(cubeSize*cubeSize));
				var val:int = k.indexOf(s.charAt(i));
				if (val>0)	grid[i] = new ValObj(val,px,py,pz,0);
				else		grid[i] = null;
			}
		}//endfunction

		/**
		 * do cube exploding animation
		 */
		private function explodeCube(callBack:Function):void
		{
			gameEnabled=false;
			var offset:Number = (cubeSize-1)/2;

			// ----- predetermine exploding travel direction
			var V:Vector.<Vector3D> = new Vector.<Vector3D>();
			for (var i:int=grid.length-1; i>-1; i--)
			{
				var c:ValObj = grid[i];
				if (c!=null)
				{
					var vx:Number = c.px-offset+Math.random()-0.5;
					var vy:Number = c.py-offset+Math.random()-0.5;
					var vz:Number = c.pz-offset+Math.random()-0.5;
					V.unshift(new Vector3D(vx*0.2,vy*0.2,vz*0.2));
				}
				else
					V.unshift(null);
			}

			var age:int=60;
			stepFn = function():void
			{
				age--;
				var i:int=0;
				var c:ValObj=null;
				if (age>0)
				{	// shake in place
					for (i=grid.length-1; i>-1; i--)
					{
						c = grid[i];
						if (c!=null)
						{
							c.tpx += (Math.random()-0.5)*0.1;
							c.tpy += (Math.random()-0.5)*0.1;
							c.tpz += (Math.random()-0.5)*0.1;
						}
					}
				}
				else
				{
					for (i=grid.length-1; i>-1; i--)
					{
						c = grid[i];
						if (c!=null)
						{
							var v:Vector3D = V[i];
							c.tpx += v.x;
							c.tpy += v.y;
							c.tpz += v.z;
							c.px = c.tpx;
							c.py = c.tpy;
							c.pz = c.tpz;
						}
					}
				}

				if (age<-60)
				{
					stepFn=null;
					gameEnabled=true;
					callBack();
				}
			}//endfunction
		}//endfunction

		/**
		 * notice with share and go rate buttons attached
		 */
		private function showDarkenNotice(txt:String,callBack:Function,showCancel:Boolean=false,showFBShare:Boolean=true,showRate:Boolean=true,color:uint=0x3399FF):Sprite
		{
			var sw:int = stage.stageWidth;
			var sh:int = stage.stageHeight;

			disableAndDarken(true);

			var s:Sprite = new TFMC();
			var tf:TextField = (TextField)(s.getChildAt(0));
			tf.autoSize = "left";
			tf.wordWrap = false;
			tf.htmlText = "<font color='#"+color.toString(16)+"'>"+txt+"</font>";
			tf.x = (stage.stageWidth-tf.width)/2;

			var btn:Sprite = null;
			btn = createTxtBtn("[CONFIRM]",function():void {mouseDownPt=null; s.parent.removeChild(s); disableAndDarken(false); callBack();});
			btn.x = (stage.stageWidth-btn.width)/2;
			s.addChild(btn);
			if (showCancel)
			{
				btn = createTxtBtn("[CANCEL]",function():void {mouseDownPt=null; s.parent.removeChild(s); disableAndDarken(false); });
				btn.x = (stage.stageWidth-btn.width)/2;
				s.addChild(btn);
			}
			if (showFBShare)
			{
				btn = createTxtBtn("[FACEBOOK SHARE]",fbShare);
				btn.x = (stage.stageWidth-btn.width)/2;
				s.addChild(btn);
			}
			if (showRate)
			{
				btn = createTxtBtn("[RATE THIS APP]",goRateApp);
				btn.x = (stage.stageWidth-btn.width)/2;
				s.addChild(btn);
			}

			// ----- auto align elements in s
			var eh:Number = 0;
			for (var i:int=s.numChildren-1; i>-1; i--)
				eh += s.getChildAt(i).height;
			var gap:Number = (sh-eh)/(s.numChildren+1);
			if (gap>60) gap = 60;
			var margin:Number = (sh-eh-gap*(s.numChildren+1))/2;
			var offY:int = sh-margin;
			for (i=s.numChildren-1; i>-1; i--)
			{
				offY -= gap + s.getChildAt(i).height;
				s.getChildAt(i).y = offY;
			}
			addChild(s);

			// ----- do fade in to prevent immediate close when click
			s.mouseChildren = false;
			var delay:int=30;
			function fadeInHandler(ev:Event):void
			{
				if (delay<=0)
				{
					s.transform.colorTransform = new ColorTransform(1,1,1,1);
					s.removeEventListener(Event.ENTER_FRAME,fadeInHandler);
					s.mouseChildren = true;
				}
				var m:Number = (30-delay)/30;
				s.transform.colorTransform = new ColorTransform(m,m,m,1);
				delay--;
			}
			fadeInHandler(null);
			s.addEventListener(Event.ENTER_FRAME,fadeInHandler);

			return s;
		}//

		/**
		 *
		 * @param	disable
		 */
		private function disableAndDarken(disable:Boolean):void
		{
			if (disable)
			{
				objM.setLightingParameters(0.2,0.2,0.2,0,1,false,true);
			}
			else
			{
				objM.setLightingParameters(0.2,0.2,0.2,1,1,true,true);
				frmM.setLightingParameters(0.2,0.2,0.2,0,1,false,true);
			}
			gameEnabled=!disable;		// prevent double popup
		}//endfunction

		/**
		 * create the standard behavior button..
		 */
		private static function createTxtBtn(txt:String,callBack:Function,color:uint=0x3399FF):Sprite
		{
			var btn:Sprite = new TFMC();
			var tf:TextField = (TextField)(btn.getChildAt(0));
			tf.autoSize = "left";
			tf.wordWrap = false;
			tf.htmlText = "<font color='#"+color.toString(16)+"'>"+txt+"</font>";
			btn.buttonMode = true;
			btn.mouseChildren = false;

			var glowStr:Number = 0;
			var mouseDownPt:Point = null;
			var endCall:Function = null;
			function mouseDownHandler(ev:Event) : void
			{
				mouseDownPt = new Point(btn.mouseX, btn.mouseY);
			}//endfunction
			function enterFrameHandler(ev:Event) : void
			{
				var bnds:Rectangle = btn.getBounds(btn);
				if (mouseDownPt==null || btn.mouseX<bnds.left || btn.mouseX>bnds.right || btn.mouseY<bnds.top || btn.mouseY>bnds.bottom)
					glowStr -= 0.05;
				else
					glowStr += 0.05;
				if (glowStr<0) 	glowStr=0;
				if (glowStr>1) 	glowStr=1;
				var sinGlowStr:Number = Math.sin(Math.PI*2/3*glowStr);
				if (glowStr==0)
				{
					btn.filters = [];
					if (endCall!=null)	endCall();
					endCall = null;
				}
				else	btn.filters = [new GlowFilter(color,1,8+sinGlowStr*8,8+sinGlowStr*8,sinGlowStr*(1+Math.random()))];
			}//endfunction
			function mouseUpHandler(ev:Event) : void
			{
				if (mouseDownPt!=null)
				{
					mouseDownPt = null;
					glowStr = 0.7;
					if (callBack!=null) endCall = callBack;
				}
			}//endfunction
			function mouseOutHandler(ev:Event) : void
			{
				mouseDownPt = null;
			}//endfunction
			function removeHandler(ev:Event) : void
			{
				btn.removeEventListener(Event.REMOVED_FROM_STAGE, removeHandler);
				btn.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				btn.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				btn.removeEventListener(MouseEvent.ROLL_OUT, mouseOutHandler);
				btn.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}//endfunction
			btn.addEventListener(Event.REMOVED_FROM_STAGE, removeHandler);
			btn.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			btn.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			btn.addEventListener(MouseEvent.ROLL_OUT, mouseOutHandler);
			btn.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			return btn;
		}//endfunction

		/**
		 * debug printout function
		 */
		private var debugTf:TextField;
		private function prn(s:String):void
		{
			if (debugTf==null)
			{
				debugTf = new TextField();
				debugTf.autoSize = "left";
				debugTf.wordWrap = false;
				debugTf.mouseEnabled = false;
				var tff:TextFormat = debugTf.defaultTextFormat;
				tff.color = 0xFFFFFF;
				debugTf.defaultTextFormat = tff;
				debugTf.text = "";
				addChild(debugTf);
			}

			debugTf.appendText(s+"\n");
		}//endfunction

		/**
		 *
		 */
		private static function charFadeSpriteSheet(c:String,n:int=4) : BitmapData
		{
			var tf:TextField = new TextField();
			tf.autoSize = "left";
			tf.wordWrap = false;
			tf.mouseEnabled = false;
			var tff:TextFormat = tf.defaultTextFormat;
			tff.color = 0xFFFFFF;
			tf.defaultTextFormat = tff;
			tf.text = c;
			return fadeSpriteSheet(tf,n);
		}//endfunction

		/**
		 * given displayObject create spritesheet of it slowly fading off
		 */
		private static function fadeSpriteSheet(d:DisplayObject,n:int=4) : BitmapData
		{
			var s:Sprite = new Sprite();
			var sc:Number = Math.min(64/d.width,64/d.height);
			d.scaleX = sc;
			d.scaleY = sc;
			d.filters = [new GlowFilter(0xFFFFFF,1,8,8,4)];
			s.addChild(d);
			var bmd:BitmapData = new BitmapData(n*64,n*64,false,0x00000000);
			for (var j:int=0; j<n; j++)
				for (var i:int=0; i<n; i++)
				{
					d.alpha = 1-(j*n+i)/(n*n);
					bmd.draw(s,new Matrix(1,0,0,1,i*64+(64-s.width)/2,j*64+(64-s.height)/2));
				}
			return bmd;
		}//endfunction

		/**
		* convenience function for quaternion multiplication
		*/
		private static function quatMult(	qax:Number,qay:Number,qaz:Number,qaw:Number,
											qbx:Number,qby:Number,qbz:Number,qbw:Number) : Vector3D
		{
			var qc:Vector3D = new Vector3D(	qax*qbw + qaw*qbx + qay*qbz - qaz*qby,	// x
											qay*qbw + qaw*qby + qaz*qbx - qax*qbz,	// y
											qaz*qbw + qaw*qbz + qax*qby - qay*qbx,	// z
											qaw*qbw - qax*qbx - qay*qby - qaz*qbz);	// w real

			return qc;
		}//endfunction

		/**
		 *
		 */
		private static function fbShare():void
		{
		}//endfunction

		/**
		 *
		 */
		private static function goRateApp():void
		{
			// App ID - Replace with your app id
			var APPLE_APP_ID:String= "884680750";
			var APP_STORE_BASE_URI:String= "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?onlyLatestVersion=false&type=Purple+Software&id=";

			// Android google play Store URIs
			var PLAY_APP_ID:String= "air.com.domain.mygame";
			var PLAY_STORE_BASE_URI:String= "market://details?id=";
			var PLAY_REVIEW:String= "&reviewId=0";

			// Open the review page in the app store
			var appUrl:String = APP_STORE_BASE_URI + APPLE_APP_ID;
			if (isAndroid())
				appUrl = PLAY_STORE_BASE_URI + PLAY_APP_ID + PLAY_REVIEW;

			// Open store URI
			var req:URLRequest = new URLRequest(appUrl);
			navigateToURL(req);

			function isAndroid():Boolean
			{
				return Capabilities.manufacturer.indexOf('Android') > -1;
			}
		}//endfunction
	}//endclass
}//endpackage

import flash.events.Event;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;
//import com.hdi.nativeExtensions.NativeAds;
//import com.hdi.nativeExtensions.NativeAdsEvent;


//import com.freshplanet.ane.AirInAppPurchase.InAppPurchase;
//import com.freshplanet.ane.AirInAppPurchase.InAppPurchaseEvent;

class InAppStore
{
//	public static var iap:InAppPurchase = null;
	public static var debugTf:TextField = null;

	public static const GOOGLE_FLAG_DEBUG:Boolean = false;
	public static const GOOGLE_LICENSE_KEY:String = "googleKey";

	public static function init():void
	{
//		iap = InAppPurchase.getInstance();
//		iap.init(GOOGLE_LICENSE_KEY, GOOGLE_FLAG_DEBUG);
		prn("init()");
	}//endfunction

	public static function purchase(productId:String,callBack:Function):void
	{
		/*
		iap.makePurchase(productId);
		function onPurchase(pe:InAppPurchaseEvent):void
		{
			var inAppData:Object =JSON.parse(pe.data);
			var receipt:Object = inAppData["receipt"];
			var productId:String = inAppData["productId"];
			// consume product if it is a consumable
			iap.removePurchaseFromQueue(productId, JSON.stringify(receipt));
			prn("PURCHASE_SUCCESSFULL "+productId);
			if (callBack!=null)	callBack(true);
		}
		function onPurchaseError(pe:InAppPurchaseEvent):void
		{
			prn("PURCHASE_ERROR "+productId);
			if (callBack!=null)	callBack(false);
		}
		iap.addEventListener(InAppPurchaseEvent.PURCHASE_ERROR, onPurchaseError);
		iap.addEventListener(InAppPurchaseEvent.PURCHASE_SUCCESSFULL, onPurchase);
		prn("purchase("+productId+","+callBack+")");
		*/
	}//endfunction

	public static function prn(s:String):void
	{
		if (debugTf==null)
		{
			debugTf = new TextField();
			var tff:TextFormat = debugTf.defaultTextFormat;
			tff.color = 0xFFFFFF;
			debugTf.defaultTextFormat = tff;
			debugTf.autoSize = "left";
			debugTf.wordWrap = false;
			debugTf.text = "InAppStore TraceOut\n";
		}
		debugTf.appendText(s+"\n");
	}//endfunction
}//endclass

/*
// displays adMob ads
class BannerAd
{
	//phone publisher id: a15135b0e76a95c
	//pad publisher id: a151407da61866f
	private static var sw:int = 0;
	private static var sh:int = 0;

	public static var adRect:Rectangle = null;
	public static var phoneAdId:String = "3b452130c60349ce";	// banner ad
	public static var padAdId:String = "19cf52920d9e4632";		// leaderboard ad
	public static var loadSuccess:Boolean = false;
	public static var showing:Boolean=false;
	public static var onShow:Function = null;
	private static var hasInit:Boolean = false;

	//===================================================================================
	public static function init(stageW:int=640,stageH:int=960) : void
	{
		if (hasInit) return;

		sw=stageW;
		sh=stageH;
		NativeAds.dispatcher.addEventListener(NativeAdsEvent.AD_RECEIVED, onAdReceived);
		hasInit=true;
	}//endfunction

	//===================================================================================
	public static function showAd() : void
	{
		if (hasInit==false) init();
		if (showing==false)
		{
			NativeAds.hideAd();
			NativeAds.deactivateAd();
			NativeAds.removeAd();
			if ((sh==480 && sw==320) || (sh==960 && sw==640) || (sh==1136 && sw==640))
			{
				NativeAds.setUnitId(phoneAdId);
				if (sh>500)
					adRect = new Rectangle(0,sh/2-50,320,50);
				else
					adRect = new Rectangle(0,sh-50,320,50);
			}
			else
			{
				NativeAds.setUnitId(padAdId);
				adRect = new Rectangle(0,1024-90,728,90);
			}
			NativeAds.setAdMode(true);//put the ads in real mode
			//initialize the ad banner with size compatible for phones, it's applicable to iOS only
			NativeAds.initAd(adRect.x,adRect.y,adRect.width,adRect.height);	// x,y,w,h
			NativeAds.showAd(adRect.x,adRect.y,adRect.width,adRect.height);
			showing = true;
		}
	}//endfunction

	//===================================================================================
	public static function hideAd() : void
	{
		NativeAds.hideAd();
		showing = false;
		if (onShow!=null) onShow(false);
	}//endfunction

	//===================================================================================
	private static function onAdReceived(e:Event=null) : void
	{
		loadSuccess=true;
		if (showing==false) NativeAds.hideAd();
		else if (onShow!=null) onShow(true);
	}//endfunction
}//endclass
*/

class SaveState
{
	public var uid:String="";			// auto generated unique for server score keeping
	public var totalPlays:uint=0;
	public var bestScore:uint=0;
	public var lastScore:uint=0;
	public var ttrate:int = 0;

	public var numUndos:int=3;
	public var curScore:int=0;			// current game score
	public var curMax:int=0;			// current game max value attained
	public var history:Vector.<String>=new Vector.<String>();

	public function SaveState():void
	{
		// ----- autoGenerate a UID
		var t:uint = new Date().getTime()*100 + int(Math.random()*100);
		var s:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
		while (t>0)
		{
			uid = s.charAt(t%s.length)+uid;
			t = int(t/s.length);
		}
	}//endfunction

	public function clone():SaveState
	{
		var s:SaveState = new SaveState();
		s.uid = uid;
		s.totalPlays=totalPlays;
		s.ttrate=ttrate;
		s.bestScore=bestScore;
		s.lastScore=lastScore;
		return s;
	}//endfunction
}//endclass

// ----- data class containing the val, posn and targ posn of cube
class ValObj
{
	var val:int=0;
	var px:Number=0;	// current position
	var py:Number=0;
	var pz:Number=0;
	var tpx:Number=0;	// target position
	var tpy:Number=0;
	var tpz:Number=0;
	var sc:Number=1;	// current scale
	var tsc:Number=1;
	var ttl:uint=int.MAX_VALUE;

	public function ValObj(value:int,x:Number,y:Number,z:Number,scale:Number=1):void
	{
		val = value;
		px = x;
		py = y;
		pz = z;
		tpx = x;
		tpy = y;
		tpz = z;
		sc = scale;
	}

	public function toString():String
	{
		return "{val:"+val + " ("+Math.round(px)+","+Math.round(py)+","+Math.round(pz)+")}";
	}//endfunction
}//endclass
