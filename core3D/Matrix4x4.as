﻿package core3D
{
	import flash.geom.Vector3D;

	/**
	* 4x4 matrix class, Transform matrix for Mesh class
	*/
	public class Matrix4x4
	{
		public var aa:Number;
		public var ab:Number;
		public var ac:Number;
		public var ad:Number;

		public var ba:Number;
		public var bb:Number;
		public var bc:Number;
		public var bd:Number;

		public var ca:Number;
		public var cb:Number;
		public var cc:Number;
		public var cd:Number;

		public var da:Number;
		public var db:Number;
		public var dc:Number;
		public var dd:Number;

		public function Matrix4x4(	aa_:Number=1,ab_:Number=0,ac_:Number=0,ad_:Number=0,
									ba_:Number=0,bb_:Number=1,bc_:Number=0,bd_:Number=0,
									ca_:Number=0,cb_:Number=0,cc_:Number=1,cd_:Number=0,
									da_:Number=0,db_:Number=0,dc_:Number=0,dd_:Number=1) : void
		{
			aa = aa_;
			ab = ab_;
			ac = ac_;
			ad = ad_;

			ba = ba_;
			bb = bb_;
			bc = bc_;
			bd = bd_;

			ca = ca_;
			cb = cb_;
			cc = cc_;
			cd = cd_;

			da = da_;
			db = db_;
			dc = dc_;
			dd = dd_;
		}//end constructor

		/**
		* returns if this matrix equals given matrix
		*/
		public function equals(M:Matrix4x4) : Boolean
		{
			return 	aa==M.aa && ab==M.ab && ac==M.ac && ad==M.ad &&
					ba==M.ba && bb==M.bb && bc==M.bc && bd==M.bd &&
					ca==M.ca && cb==M.cb && cc==M.cc && cd==M.cd &&
					da==M.da && db==M.db && dc==M.dc && dd==M.dd;
		}//endfunction

		/**
		* this=A, M=B, mult -> AB
		*/
		public function mult(M:Matrix4x4) : Matrix4x4
		{
			var naa:Number = aa*M.aa + ab*M.ba + ac*M.ca + ad*M.da;
			var nab:Number = aa*M.ab + ab*M.bb + ac*M.cb + ad*M.db;
			var nac:Number = aa*M.ac + ab*M.bc + ac*M.cc + ad*M.dc;
			var nad:Number = aa*M.ad + ab*M.bd + ac*M.cd + ad*M.dd;

			var nba:Number = ba*M.aa + bb*M.ba + bc*M.ca + bd*M.da;
			var nbb:Number = ba*M.ab + bb*M.bb + bc*M.cb + bd*M.db;
			var nbc:Number = ba*M.ac + bb*M.bc + bc*M.cc + bd*M.dc;
			var nbd:Number = ba*M.ad + bb*M.bd + bc*M.cd + bd*M.dd;

			var nca:Number = ca*M.aa + cb*M.ba + cc*M.ca + cd*M.da;
			var ncb:Number = ca*M.ab + cb*M.bb + cc*M.cb + cd*M.db;
			var ncc:Number = ca*M.ac + cb*M.bc + cc*M.cc + cd*M.dc;
			var ncd:Number = ca*M.ad + cb*M.bd + cc*M.cd + cd*M.dd;

			var nda:Number = da*M.aa + db*M.ba + dc*M.ca + dd*M.da;
			var ndb:Number = da*M.ab + db*M.bb + dc*M.cb + dd*M.db;
			var ndc:Number = da*M.ac + db*M.bc + dc*M.cc + dd*M.dc;
			var ndd:Number = da*M.ad + db*M.bd + dc*M.cd + dd*M.dd;

			return new Matrix4x4(	naa,nab,nac,nad,
								 	nba,nbb,nbc,nbd,
									nca,ncb,ncc,ncd,
									nda,ndb,ndc,ndd);

		}//end Function

		/**
		* append multiplication to target matrix M -> AM
		*/
		public static function appendMult(	M:Matrix4x4,
											aa:Number,ab:Number,ac:Number,ad:Number,
											ba:Number,bb:Number,bc:Number,bd:Number,
											ca:Number,cb:Number,cc:Number,cd:Number,
											da:Number,db:Number,dc:Number,dd:Number) : Matrix4x4
		{
			var naa:Number = aa*M.aa + ab*M.ba + ac*M.ca + ad*M.da;
			var nab:Number = aa*M.ab + ab*M.bb + ac*M.cb + ad*M.db;
			var nac:Number = aa*M.ac + ab*M.bc + ac*M.cc + ad*M.dc;
			var nad:Number = aa*M.ad + ab*M.bd + ac*M.cd + ad*M.dd;

			var nba:Number = ba*M.aa + bb*M.ba + bc*M.ca + bd*M.da;
			var nbb:Number = ba*M.ab + bb*M.bb + bc*M.cb + bd*M.db;
			var nbc:Number = ba*M.ac + bb*M.bc + bc*M.cc + bd*M.dc;
			var nbd:Number = ba*M.ad + bb*M.bd + bc*M.cd + bd*M.dd;

			var nca:Number = ca*M.aa + cb*M.ba + cc*M.ca + cd*M.da;
			var ncb:Number = ca*M.ab + cb*M.bb + cc*M.cb + cd*M.db;
			var ncc:Number = ca*M.ac + cb*M.bc + cc*M.cc + cd*M.dc;
			var ncd:Number = ca*M.ad + cb*M.bd + cc*M.cd + cd*M.dd;

			var nda:Number = da*M.aa + db*M.ba + dc*M.ca + dd*M.da;
			var ndb:Number = da*M.ab + db*M.bb + dc*M.cb + dd*M.db;
			var ndc:Number = da*M.ac + db*M.bc + dc*M.cc + dd*M.dc;
			var ndd:Number = da*M.ad + db*M.bd + dc*M.cd + dd*M.dd;

			M.aa=naa; M.ab=nab; M.ac=nac; M.ad=nad;
			M.ba=nba; M.bb=nbb; M.bc=nbc; M.bd=nbd;
			M.ca=nca; M.cb=ncb; M.cc=ncc; M.cd=ncd;
			M.da=nda; M.db=ndb; M.dc=ndc; M.dd=ndd;

			return M;
		}//endfunction

		/**
		* returns the determinant of this 4x4 matrix
		*/
		public function determinant() : Number
		{
			return    aa*bb*cc*dd + aa*bc*cd*db + aa*bd*cb*db
					+ ab*ba*cd*dc + ab*bc*ca*dd + ab*bd*cc*da
					+ ac*ba*cb*dd + ac*bb*cd*da + ac*bd*ca*db
					+ ad*ba*cc*db + ad*bb*ca*dc + ad*bc*cb*da
					- aa*bb*cd*dc - aa*bc*cb*dd - aa*bd*cc*db
					- ab*ba*cc*dd - ab*bc*cd*da - ab*bd*ca*dc
					- ac*ba*cd*db - ac*bb*ca*dd - ac*bd*cb*da
					- ad*ba*cb*dc - ad*bb*cc*da - ad*bc*ca*db;
		}//endfunction

		/**
		* returns the determinant if the inner 3x3 matrix, which is also the scaling factor
		*/
		public function determinant3() : Number
		{
			// aei+bfg+cdh-ceg-bdi-afh
			return aa*bb*cc + ab*bc*ca + ac*ba*cb - ac*bb*ca - ab*ba*cc - aa*bc*cb;
		}//endfunction

		/**
		* returns the inverse matrix of this matrix
		*/
		public function inverse() : Matrix4x4
		{
			var _det:Number = determinant();
			if (_det==0)	return null;
			var naa:Number = bb*cc*dd + bc*cd*db + bd*cb*dc - bb*cd*dc - bc*cb*dd - bd*cc*db;
			var nab:Number = ab*cd*dc + ac*cb*dd + ad*cc*db - ab*cc*dd - ac*cd*db - ad*cb*dc;
			var nac:Number = ab*bc*dd + ac*bd*db + ad*bb*dc - ab*bd*dc - ac*bb*dd - ad*bc*db;
			var nad:Number = ab*bd*cc + ac*bb*cd + ad*bc*cb - ab*bc*cd - ac*bd*cb - ad*bb*cc;
			var nba:Number = ba*cd*dc + bc*ca*dd + bd*cc*da - ba*cc*dd - bc*cd*da - bd*ca*dc;
			var nbb:Number = aa*cc*dd + ac*cd*da + ad*ca*dc - aa*cd*dc - ac*ca*dd - ad*cc*da;
			var nbc:Number = aa*bd*dc + ac*ba*dd + ad*bc*da - aa*bc*dd - ac*bd*da - ad*ba*dc;
			var nbd:Number = aa*bc*cd + ac*bd*ca + ad*ba*cc - aa*bd*cc - ac*ba*cd - ad*bc*ca;
			var nca:Number = ba*cb*dd + bb*cd*da + bd*ca*db - ba*cd*db - bb*ca*dd - bd*cb*da;
			var ncb:Number = aa*cd*db + ab*ca*dd + ad*cb*da - aa*cb*dd - ab*cd*da - ad*ca*db;
			var ncc:Number = aa*bb*dd + ab*bd*da + ad*ba*db - aa*bd*db - ab*ba*dd - ad*bb*da;
			var ncd:Number = aa*bd*cb + ab*ba*cd + ad*bb*ca - aa*bb*cd - ab*bd*ca - ad*ba*cb;
			var nda:Number = ba*cc*db + bb*ca*dc + bc*cb*da - ba*cb*dc - bb*cc*da - bc*ca*db;
			var ndb:Number = aa*cb*dc + ab*cc*da + ac*ca*db - aa*cc*db - ab*ca*dc - ac*cb*da;
			var ndc:Number = aa*bc*db + ab*ba*dc + ac*bb*da - aa*bb*dc - ab*bc*da - ac*ba*db;
			var ndd:Number = aa*bb*cc + ab*bc*ca + ac*ba*cb - aa*bc*cb - ab*ba*cc - ac*bb*ca;
			_det = 1/_det;	// determinant inverse, to prevent 16 divisions
			return new Matrix4x4(	naa*_det,nab*_det,nac*_det,nad*_det,
								 	nba*_det,nbb*_det,nbc*_det,nbd*_det,
									nca*_det,ncb*_det,ncc*_det,ncd*_det,
									nda*_det,ndb*_det,ndc*_det,ndd*_det);
		}//endfunction

		/*
		* returns new matrix with exact cloned values
		*/
		public function clone() : Matrix4x4
		{
			return new Matrix4x4(aa,ab,ac,ad, ba,bb,bc,bd, ca,cb,cc,cd, da,db,dc,dd);
		}//endfunction

		/**
		* returns new transform matrix scaled by (xs,ys,zs)
		*/
		public function scale(xs:Number,ys:Number,zs:Number) : Matrix4x4
		{
			var naa:Number = xs;
			var nab:Number = 0;
			var nac:Number = 0;
			var nad:Number = 0;

			var nba:Number = 0;
			var nbb:Number = ys;
			var nbc:Number = 0;
			var nbd:Number = 0;

			var nca:Number = 0;
			var ncb:Number = 0;
			var ncc:Number = zs;
			var ncd:Number = 0;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;
			/*
			var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function

		/**
		* returns new transform matrix rotated about Z
		*/
		public function rotZ(a:Number) : Matrix4x4
		{
			var cosA:Number = Math.cos(a);
			var sinA:Number = Math.sin(a);

			var naa:Number = cosA;
			var nab:Number =-sinA;
			var nac:Number = 0;
			var nad:Number = 0;

			var nba:Number = sinA;
			var nbb:Number = cosA;
			var nbc:Number = 0;
			var nbd:Number = 0;

			var nca:Number = 0;
			var ncb:Number = 0;
			var ncc:Number = 1;
			var ncd:Number = 0;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;
			/*
			var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function rotZ

		/**
		* returns new transform matrix rotated about Y
		*/
		public function rotY(a:Number) : Matrix4x4
		{
			var cosA:Number = Math.cos(a);
			var sinA:Number = Math.sin(a);

			var naa:Number = cosA;
			var nab:Number = 0;
			var nac:Number = sinA;
			var nad:Number = 0;

			var nba:Number = 0;
			var nbb:Number = 1;
			var nbc:Number = 0;
			var nbd:Number = 0;

			var nca:Number =-sinA;
			var ncb:Number = 0;
			var ncc:Number = cosA;
			var ncd:Number = 0;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;
			/*
			var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function rotY

		/**
		* returns new transform matrix rotated about X
		*/
		public function rotX(a:Number) : Matrix4x4
		{
			var cosA:Number = Math.cos(a);
			var sinA:Number = Math.sin(a);

			var naa:Number = 1;
			var nab:Number = 0;
			var nac:Number = 0;
			var nad:Number = 0;

			var nba:Number = 0;
			var nbb:Number = cosA;
			var nbc:Number =-sinA;
			var nbd:Number = 0;

			var nca:Number = 0;
			var ncb:Number = sinA;
			var ncc:Number = cosA;
			var ncd:Number = 0;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;
			/*
			var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function rotX

		/**
		* returns new transform matrix rotated by angle specified by 2 vectors
		*/
		public function rotFromTo(ax:Number,ay:Number,az:Number,bx:Number,by:Number,bz:Number) : Matrix4x4
		{
			var _al:Number = 1/Math.sqrt(ax*ax+ay*ay+az*az);
			ax*=_al;
			ay*=_al;
			az*=_al;
			var _bl:Number = 1/Math.sqrt(bx*bx+by*by+bz*bz);
			bx*=_bl;
			by*=_bl;
			bz*=_bl;

			// ----- reversed direction special case
			if ((ax+bx)*(ax+bx) + (ay+by)*(ay+by) + (az+bz)*(az+bz)<0.0000001)
			{
				var fM:Matrix4x4 = new Matrix4x4(-1,0,0,0, 0,-1,0,0, 0,0,1,0, 0,0,0,1);	// flip from up to down
				if (ay>0)
					fM = fM.mult(new Matrix4x4().rotFromTo(ax,ay,az,0,1,0)).rotFromTo(0,1,0,ax,ay,az);
				else
					fM = fM.mult(new Matrix4x4().rotFromTo(ax,ay,az,0,-1,0)).rotFromTo(0,-1,0,ax,ay,az);

				return appendMult(	this.clone(),
									fM.aa,fM.ab,fM.ac,fM.ad,
									fM.ba,fM.bb,fM.bc,fM.bd,
									fM.ca,fM.cb,fM.cc,fM.cd,
									fM.da,fM.db,fM.dc,fM.dd);
			}
			// ----- no rotation special case
			else if ((ax-bx)*(ax-bx) + (ay-by)*(ay-by) + (az-bz)*(az-bz)<0.0000001)
			{
				return this.clone();
			}

			// normal by determinant Tn
			var nx:Number = ay*bz-az*by;	//	normal x for the triangle
			var ny:Number = az*bx-ax*bz;	//	normal y for the triangle
			var nz:Number = ax*by-ay*bx;	//	normal z for the triangle
			return rotAbout(nx,ny,nz,Math.acos(ax*bx+ay*by+az*bz));
		}//endfunction

		/**
		* returns new transform matrix rotated about given axis (ux,uy,uz)
		*/
		public function rotAbout(ux:Number,uy:Number,uz:Number,a:Number) : Matrix4x4
		{
			var ul:Number = Math.sqrt(ux*ux + uy*uy + uz*uz);
			if (ul==0)	return this;
			ux/=ul;
			uy/=ul;
			uz/=ul;

			var cosA:Number = Math.cos(a);
			var sinA:Number = Math.sin(a);

			var naa:Number = ux*ux + (1-ux*ux)*cosA;
			var nab:Number = ux*uy*(1-cosA) - uz*sinA;
			var nac:Number = ux*uz*(1-cosA) + uy*sinA;
			var nad:Number = 0;

			var nba:Number = ux*uy*(1-cosA) + uz*sinA;
			var nbb:Number = uy*uy + (1-uy*uy)*cosA;
			var nbc:Number = uy*uz*(1-cosA) - ux*sinA;
			var nbd:Number = 0;

			var nca:Number = ux*uz*(1-cosA) - uy*sinA;
			var ncb:Number = uy*uz*(1-cosA) + ux*sinA;
			var ncc:Number = uz*uz + (1-uz*uz)*cosA;
			var ncd:Number = 0;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;

			/*var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function rotAbout

		/**
		* given rotation vector, apply rotation to matrix,
		*/
		public function rotate(rx:Number,ry:Number,rz:Number) : Matrix4x4
		{
			var rl:Number = Math.sqrt(rx*rx+ry*ry+rz*rz);
			return rotAbout(rx,ry,rz,rl);
		}//endfunction

		/**
		* returns new transform matrix translated (tx,ty,tz)
		*/
		public function translate(tx:Number,ty:Number,tz:Number) : Matrix4x4
		{
			var naa:Number = 1;
			var nab:Number = 0;
			var nac:Number = 0;
			var nad:Number = tx;

			var nba:Number = 0;
			var nbb:Number = 1;
			var nbc:Number = 0;
			var nbd:Number = ty;

			var nca:Number = 0;
			var ncb:Number = 0;
			var ncc:Number = 1;
			var ncd:Number = tz;

			var nda:Number = 0;
			var ndb:Number = 0;
			var ndc:Number = 0;
			var ndd:Number = 1;
			/*
			var M:Matrix4x4 =  new Matrix4x4(	naa,nab,nac,nad,
												nba,nbb,nbc,nbd,
												nca,ncb,ncc,ncd,
												nda,ndb,ndc,ndd);
			return M.mult(this);*/
			return appendMult(	this.clone(),
								naa,nab,nac,nad,
								nba,nbb,nbc,nbd,
								nca,ncb,ncc,ncd,
								nda,ndb,ndc,ndd);
		}//end Function translate

		/**
		* returns new transformed vector3D
		*/
		public function transform(v:Vector3D) : Vector3D
		{
			return new Vector3D(v.x*aa+v.y*ab+v.z*ac+ad,
								v.x*ba+v.y*bb+v.z*bc+bd,
								v.x*ca+v.y*cb+v.z*cc+cd,
								0);
		}//endfunction

		/*
		* returns new rotated vector3D
		*/
		public function rotateVector(v:Vector3D) : Vector3D
		{
			return new Vector3D(v.x*aa+v.y*ab+v.z*ac,
								v.x*ba+v.y*bb+v.z*bc,
								v.x*ca+v.y*cb+v.z*cc,v.w);
		}//endfunction

		/**
		* returns the string printout of the values
		*/
		public function toString() : String
		{
			return  "\n"+
					"|"+padN(aa,5)+","+padN(ab,5)+","+padN(ac,5)+","+padN(ad,5)+"|\n"+
					"|"+padN(ba,5)+","+padN(bb,5)+","+padN(bc,5)+","+padN(bd,5)+"|\n"+
					"|"+padN(ca,5)+","+padN(cb,5)+","+padN(cc,5)+","+padN(cd,5)+"|\n"+
					"|"+padN(da,5)+","+padN(db,5)+","+padN(dc,5)+","+padN(dd,5)+"|\n";
		}//endfunction

		/**
		* returns the quaternion representation of the matrix rotation component
		* code from http://www.cs.princeton.edu/~gewang/projects/darth/stuff/quat_faq.html#Q55
		*/
		public function rotationQuaternion() : Vector3D
		{
			var t:Number = 1+aa+bb+cc;	// trace of the matrix
			var s:Number = 0;
			var quat:Vector3D = new Vector3D();
			if (t>0.0000001)
			{
				s = Math.sqrt(t)*2;
				quat.x = (cb-bc)/s;
				quat.y = (ac-ca)/s;
				quat.z = (ba-ab)/s;
				quat.w = 0.25*s
			}
			else if (t==0)		// added to attempt a fix on 180 rotations...
			{
				if (aa==1)		quat.x=1;	// rot 180 about x axis
				else if (bb==1)	quat.y=1;	// rot 180 about y axis
				else 			quat.z=1;	// rot 180 about z axis
			}
			else if (aa>bb && aa>cc)	// column 0
			{
				t = 1+aa-bb-cc;
				s = Math.sqrt(t)*2;
				quat.x = 0.25*s;
				quat.y = (ba+ab)/s;
				quat.z = (ac+ca)/s;
				quat.w = (cb-bc)/s;
			}
			else if (bb>cc)
			{
				t = 1+bb-aa-cc;
				s = Math.sqrt(t)*2;
				quat.x = (ba+ab)/s;
				quat.y = 0.25*s;
				quat.z = (cb+bc)/s;
				quat.w = (ac-ca)/s;
			}
			else
			{
				t = 1+cc-aa-bb;
				s = Math.sqrt(t)*2;
				quat.x = (ac+ca)/s;
				quat.y = (cb+bc)/s;
				quat.z = 0.25*s;
				quat.w = (ba-ab)/s;
			}

			return quat;
		}//endfunction

		/**
		* returns the matrix representation of quaternion rotation w + xi + yj + zk
		*/
		public static function quaternionToMatrix(w:Number,x:Number,y:Number,z:Number) : Matrix4x4
		{
			var l:Number = Math.sqrt(w*w + x*x + y*y + z*z);
			if (l==0)	return new Matrix4x4();
			w/=l;	x/=l;	y/=l;	z/=l;
			var naa:Number = 1 - 2*y*y - 2*z*z;
			var nab:Number = 2*x*y - 2*w*z;
			var nac:Number = 2*x*z + 2*w*y;

			var nba:Number = 2*x*y + 2*w*z;
			var nbb:Number = 1 - 2*x*x - 2*z*z;
			var nbc:Number = 2*y*z - 2*w*x;

			var nca:Number = 2*x*z - 2*w*y;
			var ncb:Number = 2*y*z + 2*w*x;
			var ncc:Number = 1 - 2*x*x - 2*y*y;

			return new Matrix4x4(	naa,nab,nac,0,
									nba,nbb,nbc,0,
									nca,ncb,ncc,0);
		}//endfunction

		/**
		 * returns the quaternion multiplication pxq in (w + xi + yj + zk)
		 */
		public static function quatMult(p:Vector3D,q:Vector3D) : Vector3D
		{
			return new Vector3D(q.w*p.x + q.x*p.w - q.y*p.z + q.z*p.y,
													q.w*p.y + q.x*p.z + q.y*p.w - q.z*p.x,
													q.w*p.z - q.x*p.y + q.y*p.x + q.z*p.w,
													q.w*p.w - q.x*p.x - q.y*p.y - q.z*p.z);
		}//endfunction

		protected function padN(v:Number,n:int) : String
		{
			v = Math.round(v*100)/100;
			var s:String = v+"";
			while (s.length<n)	s = " "+s;
			return s;
		}
	}//end class

}//end Package
