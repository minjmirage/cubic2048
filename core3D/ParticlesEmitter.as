package core3D
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	/**
	* Author: Lin Minjiang	2012/07/10	updated
	* Creates an emitter to emit particles of texture sequence specified by given movieClip.
	* Supports 120 animated billboard particles on a single mesh
	*/
	public class ParticlesEmitter
	{
		public var skin:Mesh;
		public var PData:Vector.<VertexData>;	// position, scaling and  of each particle
		private var Pool:Vector.<VertexData>;	// used VertexData for reuse

		public var spriteSheet:BitmapData;		// the spritesheet containing movieclip sequence
		public var totalFrames:uint=0;				// total frames of the movieclip

		public var wind:Vector3D;							// wind affecting the particles
		public var slowdown:Number=0.85;			// slowdown factor

		private var lifeTime:uint=0;					// particle time to live after spawn
		private var nsp:uint = 1;							// number of sprites in a row in spritesheet
		private var numPerMesh:int = 120;			//
		private var scale:Number = 1;
		private var blendMode:String= "alpha";

		/**
		* creates a 120 batch rendered animated bitmap particles at given positions
		*/
		public function ParticlesEmitter(sheet:BitmapData,frames:uint,sc:Number=1,blend:String="alpha") : void
		{
			var i:int=0;

			wind = new Vector3D(0,0,0);		// default wind

			// ----- generate spriteSheet ---------------------------
			spriteSheet = sheet;
			nsp = Math.ceil(Math.sqrt(frames));	// number of sprites in a row
			totalFrames = frames;
			lifeTime = totalFrames;
			scale = sc;
			blendMode = blend;

			// ----- default particle positions if not given --------
			PData = new Vector.<VertexData>();
			Pool = new Vector.<VertexData>();

			skin = new Mesh();
		}//endfunction

		/**
		* generates mesh for particles rendering
		*/
		private function createNewRenderMesh():Mesh
		{
			if (Mesh.context3d!=null && Mesh.context3d.profile.indexOf("standard")!=-1)
				numPerMesh = 242;
			else
				numPerMesh = 120;

			var sw:int = spriteSheet.width/nsp;		// width of single sprite in sheet
			var sh:int = spriteSheet.height/nsp;	// height of single sprite in sheet

			// ----- create bitmap planes geometry ------------------
			var idxOff:int = 7;			// vertex constants register offset
			var V:Vector.<Number> = new Vector.<Number>();	// vertices data
			var I:Vector.<uint> = new Vector.<uint>();			// indices data
			var w2:Number = sw/250*scale;
			var h2:Number = sh/250*scale;
			var f:Number = 1/nsp;
			for (var i:int=0; i<numPerMesh; i++)
			{
				V.push(-w2,-h2,0, 0,0, idxOff+i);		// vx,vy,vz, u,v, idx top left
				V.push( w2,-h2,0, f,0, idxOff+i);		// vx,vy,vz, u,v, idx top right
				V.push( w2, h2,0, f,f, idxOff+i);		// vx,vy,vz, u,v, idx bottom right
				V.push(-w2, h2,0, 0,f, idxOff+i);		// vx,vy,vz, u,v, idx bottom left

				I.push(i*4+0,i*4+1,i*4+2);		// top right tri
				I.push(i*4+0,i*4+2,i*4+3);		// bottom left tri
			}
			var m:Mesh = new Mesh();
			m.castsShadow=false;
			m.depthWrite = false;
			m.setLightingParameters(1,1,1,0,0,false);
			m.material.setTexMap(spriteSheet);
			m.material.setBlendMode(blendMode);
			m.setParticles(V,I);
			return m;
		}//endfunction

		/**
		* sets time to live for the particles
		*/
		public function setLifetime(t:uint) : void
		{
			for (var i:int=PData.length-1; i>=0; i--)
				if (PData[i].idx>=lifeTime)
					PData[i].idx=t;
			lifeTime = t;
		}//endfunction

		/**
		* batch emit number of a particles at (px,py,pz) of velocity (vx,vy,vz) 0<=sc<=0.9999 with random deviation, to reduce function calls
		*/
		public function batchEmit(n:uint=1,px:Number=0,py:Number=0,pz:Number=0,vx:Number=0,vy:Number=0,vz:Number=0,dev:Number=0,sc1:Number=1,sc2:Number=0.5) : void
		{
			if (sc1>0.9999)	sc1=0.9999;
			if (sc1<0)		sc1=0;
			if (sc2>0.9999)	sc2=0.9999;
			if (sc2<0)		sc2=0;
			for (var i:int=0; i<n; i++)
			{
				var p:VertexData = null;
				if (Pool.length>0)
					p = Pool.pop();
				else
					p = new VertexData(0,0,0, 0,0,0, 0,0,0, totalFrames);
				p.nx = px;		// position
				p.ny = py;
				p.nz = pz;
				var rx:Number = Math.random()-0.5;
				var ry:Number = Math.random()-0.5;
				var rz:Number = Math.random()-0.5;
				var r:Number = Math.random()*dev/Math.sqrt(rx*rx+ry*ry+rz*rz);
				p.vx = vx + rx*r;		// velocity
				p.vy = vy + ry*r;
				p.vz = vz + rz*r;
				p.u = 0;		// UV coordinate of sprite sheet
				p.v = 0;
				r = Math.random();
				p.w = sc1*r+sc2*(1-r);		// particle scale
				p.idx = 0;		// frame index
				PData.unshift(p);
			}
		}//endfunction

		/**
		* emit a particle at (px,py,pz) of velocity (vx,vy,vz) 0<=sc<=0.9999
		*/
		public function emit(px:Number=0,py:Number=0,pz:Number=0,vx:Number=0,vy:Number=0,vz:Number=0,sc:Number=1) : void
		{
			if (sc>0.9999)	sc=0.9999;
			if (sc<0)		sc=0;
			var p:VertexData = null;
			if (Pool.length>0)
				p = Pool.pop();
			else
				p = new VertexData(0,0,0, 0,0,0, 0,0,0, totalFrames);
			p.nx = px;		// position
			p.ny = py;
			p.nz = pz;
			p.vx = vx;		// velocity
			p.vy = vy;
			p.vz = vz;
			p.u = 0;		// UV coordinate of sprite sheet
			p.v = 0;
			p.w = sc;		// particle scale
			p.idx = 0;		// frame index
			PData.unshift(p);		// to front of Q
		}//endfunction

		/**
		* clears all existing particles
		*/
		public function reset() : void
		{
			while (PData.length>0)
				Pool.push(PData.pop());
			for (var i:int=skin.numChildren()-1; i>-1; i--)
				skin.getChildAt(i).jointsData=null;	// to abort render
		}//endfunctioh

		/**
		* updates the particles positions and each particle to lookAt (lx,ly,lz)
		*/
		public function update(lx:Number,ly:Number,lz:Number,isPaused:Boolean=false) : void
		{
			if (Mesh.context3d==null) return;

			// ----- transform look at point to local coordinates ---
			var pt:Vector3D = new Vector3D(lx,ly,lz);
			if (skin.transform==null)	skin.transform = new Matrix4x4();
			var invT:Matrix4x4 = skin.transform.inverse();
			pt = invT.transform(pt);	// posn relative to particles space

			// ----- write particles positions data -----------------
			var T:Vector.<Number> = null;
			var mcnt:int = 0;
			var pcnt:int = numPerMesh;
			var rmesh:Mesh = null;

			for (var i:int=PData.length-1; i>-1; i--)
			{
				if (pcnt>=numPerMesh)
				{
					if (T!=null)
					{
						rmesh = skin.getChildAt(mcnt-1);
						rmesh.trisCnt = pcnt*2;
						rmesh.jointsData = T;		// send particle transforms to mesh for GPU transformation
					}
					T = Vector.<Number>([0,1,2,nsp, pt.x,pt.y,pt.z,0.001]);	// look at point, nsp=num of cols in spritesheet, 0.001 to address rounding error
					mcnt++;
					pcnt=0;
					if (skin.numChildren()<mcnt)
						skin.addChild(createNewRenderMesh());
				}//endif

				pcnt++;
				var p:VertexData = PData[i];
				T.push(p.nx,p.ny,p.nz,p.idx%totalFrames+p.w);		// tx,ty,tx,idx+scale
				if (!isPaused)
				{
					p.vx = p.vx*slowdown + wind.x;
					p.vy = p.vy*slowdown + wind.y;
					p.vz = p.vz*slowdown + wind.z;
					p.nx+=p.vx;
					p.ny+=p.vy;
					p.nz+=p.vz;
					p.idx++;	// increment frame index
					if (p.idx>=lifeTime)
					{
						p.w=0;		// last elements in PData are oldest
						Pool.push(PData.pop());
					}
				}
			}//endfor
			if (T!=null && pcnt>0)	// set the render data for the last mesh
			{
				rmesh = skin.getChildAt(mcnt-1);
				rmesh.trisCnt = pcnt*2;
				rmesh.jointsData = T;		// send particle transforms to mesh for GPU transformation
			}

			// ----- disable rest of unused render meshes
			for (i=skin.numChildren()-1; i>=mcnt; i--)
			{
				rmesh = skin.getChildAt(i)
				rmesh.jointsData = null;
				rmesh.trisCnt = 0;
			}
		}//endfuntcion

		/**
		* convenience function to create from a given movieClip
		*/
		public static function fromMovieClip(mc:MovieClip,sc:Number=1,blend:String="alpha") : ParticlesEmitter
		{
			return new ParticlesEmitter(movieClipToSpritesheet(mc),mc.totalFrames,sc,blend);
		}//endfunction

		/**
		* given a multiframe movieClip instance, returns a single bitmapData spritesheet of all frame captures
		*/
		public static function movieClipToSpritesheet(mc:MovieClip,stepRot:Number=0) : BitmapData
		{
			var w:uint = Math.ceil(mc.width);
			var h:uint = Math.ceil(mc.height);
			var n:uint = Math.ceil(Math.sqrt(mc.totalFrames));	// number of rows,cols for generated bmd
			var bmd:BitmapData = new BitmapData(w*n,h*n,true,0x00000000);

			// ----- start bitmap capture ---------------------------
			var rot:Number = 0;
			for (var i:int=0; i<mc.totalFrames; i++)
			{
				mc.gotoAndStop(i+1);
				var bnds:Rectangle = mc.getBounds(mc);
				var m:Matrix = new Matrix(1,0,0,1);
				m.translate(-w/2,-h/2);
				m.rotate(rot);
				m.translate(w/2,h/2);
				m.translate(w*(i%n)-bnds.left,h*int(i/n)-bnds.top);
				bmd.draw(mc,m);
				rot+=stepRot;
			}

			// ----- sizing down bitmap so width,height is power of 2
			var nw:uint = 1;
			var nh:uint = 1;
			while (nw<=bmd.width)	nw*=2;
			while (nh<=bmd.height)	nh*=2;
			nw/=2;	nh/=2;
			if (nw>2048) nw=2048;
			if (nh>2048) nh=2048;
			var nbmd:BitmapData = new BitmapData(nw,nh,true,0x00000000);
			nbmd.draw(bmd,new Matrix(nw/bmd.width,0,0,nh/bmd.height,0,0),null,null,null,true);

			return nbmd;
		}//endfunction
	}//endclass
}//endpackage
