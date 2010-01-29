#pragma rtGlobals=1		// Use modern global access method.

// Load in _rf files 
//
// Run loop_RFs()
// Run Cluster()
// display proj2 vs proj1
//
// Indentify the different cell types based off of the clusters in the above plot
// Input the number corresponding to the color that you want into the wave shape
//		(see below for color to number identification)
//
// run Graph()
//
//
// The procedure can fail if it cannot fit a 2D gaussian to your cell. If that happens, just reset the
//		for loop in the loop_RF procedure
//
// The output will be cn"_pos" and cn"_ker". The former is a matrix contour of the fit for the
//		an upsampled version of spatial RF, the later is the first principal component 
//		of all the kernels in the receptive field
//
//		19=red (standard adapting/biphasic OFF)
//		16=pink (slow OFF)
//		17=green (medium OFF)
//		29=yellow (monophasic OFF)
//		1=light blue (fast ON)
//		43=blue (slow ON)
//		8=black (reverse adapting cells/biphasic OFF)
//		0=grey (unclassified)
//			paranthetical names refer to the identification in Segev et a. J. Neurophys 2006

CONSTANT red=19,pink=16,green=17,yellow=29,lightBlue=1,blue=43,black=8,grey=0

function loop_RFs()
	string list=wavelist("*_rf",";","")
	string /g suffix
	variable dummy
	sscanf stringfromlist(0,list),"c%d%s",dummy,suffix
	variable /g numcells=itemsinlist(list)
	make /o/n=(numcells,7) Parameters
	variable i
	for(i=1;i<=numcells;i+=1)
		Get_RF("c"+num2str(i))
		wave w_coef
		Parameters[i-1][]=w_coef[q]
		if(i==numCells || mod(i,10)==0)
			printf "c%g\r",i
		else
			printf "c%g,",i
		endif
	endfor
end

function Get_RF(cn)
	string cn
	SVAR suffix
	variable subtr=160/BOX_PIX // BOX_PIX is a constant from MapRF and 160 is the number of pixels in 1mm
	wave RF=$cn+suffix
	GetPC(cn)
	threshrf(RF,0,-.025,-.125)
	wave rf_thr
	make /o/n=(1000,1000) upsmpl
	wavestats /q  rf_thr
	setscale /p x,v_maxRowLoc-subtr,.02,upsmpl
	setscale /p y,v_maxColLoc-subtr,.02,upsmpl
	upsmpl=rf_thr(x)(y)
	CurveFit/NTHR=1/TBOX=0/w=0/q Gauss2D  upsmpl /D
	wave fit_upsmpl
	wavestats /q fit_upsmpl
	fit_upsmpl-=v_min
	wavestats /q fit_upsmpl
	fit_upsmpl/=v_max
	duplicate /o fit_upsmpl $cn+"_pos"
end

function GetPC(cn)
	string cn
	SVAR suffix
	wave rf=$cn+suffix
	variable strt
	variable range=9
	variable fromx,fromy
	make /o/n=(range^2,dimsize(rf,2)) kers
	wavestats /q rf
	fromx=v_maxRowLoc*(abs(v_min)<v_max)+v_minRowLoc*(abs(v_min)>v_max)-floor(range/2)
	fromy=v_maxColLoc*(abs(v_min)<v_max)+v_minColLoc*(abs(v_min)>v_max)-floor(range/2)
	variable i,j
	for(i=0;i<range;i+=1)
		for(j=0;j<range;j+=1)
			kers[j+(i*9)][]=rf[i+fromx][j+fromy][q]
		endfor
	endfor
	MatrixMultiply kers /t,kers
	MatrixEigenV /SYM/EVEC m_product
	wave m_eigenvectors
	setscale /p x,dimoffset(RF,2),dimdelta(RF,2),m_eigenvectors
	make /o/n=(dimsize(m_eigenvectors,0)) PC1
	strt=-(dimoffset(RF,2)+dimdelta(RF,2)*dimsize(RF,2)-dimdelta(RF,2))
	setscale /p x,strt,dimdelta(RF,2),PC1
	PC1=m_eigenvectors(-x)[dimsize(m_eigenvectors,1)-1]
	wavestats /q RF
	if(v_max>abs(v_min))
		wavestats /q PC1
		if(abs(v_min)>v_max)
			PC1*=-1
		endif
	else
		wavestats /q PC1
		if(v_max>abs(v_min))
			PC1*=-1
		endif
	endif
	duplicate /o PC1 $cn+"_ker"
end

function Cluster()
	NVAR numcells
	SVAR suffix
	wave RF=$"c1"+suffix
	variable numKers=max(3,ceil(dimsize(RF,2)/numcells))
	variable strt=-(dimoffset(RF,2)+dimdelta(RF,2)*dimsize(RF,2)-dimdelta(RF,2))
	make /o/n=(numCells*numKers,dimsize(RF,2)) A1
	setscale /p y,strt,dimdelta(RF,2),A1
	variable i,j,k=0
	for(i=1;i<=numCells;i+=1)
		wave RF=$"c"+num2str(i)+suffix
		threshrf(RF,0,-.025,-.125)
		wave rf_thr 
		for(j=0;j<numKers;j+=1)
			wavestats /q rf_thr 
			A1[k][]=RF[v_maxRowLoc][v_maxColLoc](-y)
			rf_thr[v_maxRowLoc][v_maxColLoc]=0
			k+=1
		endfor
	endfor
	MatrixMultiply A1/T,A1
	wave m_product
	MatrixEigenV /SYM/EVEC m_product
	wave m_eigenvectors
	wavestats /q m_eigenvectors
	m_eigenvectors*=(-1)^(v_max<0)
	make /o/n=(dimsize(m_eigenvectors,0)) PC1,PC2
	PC1=m_eigenvectors[p][dimsize(m_eigenvectors,0)-1]
	PC2=m_eigenvectors[p][dimsize(m_eigenvectors,0)-2]
	make /o/n=(numCells) Proj1,Proj2
	for(i=0;i<numpnts(Proj1);i+=1)
		wave ker=$"c"+num2str(i+1)+"_ker"
		Proj1[i]=MatrixDot(ker,PC1)
		Proj2[i]=MatrixDot(ker,PC2)
	endfor
	make /o/n=(numcells) shape=19
end

function Graph()
	wave shape
	NVAR numCells
	DoWindow Times
	if(V_flag!=0)
		killwindow Times
	endif
	DoWindow Spaces
	if(V_flag!=0)
		killwindow Spaces
	endif
	display
	dowindow /c Times
	display
	dowindow /c Spaces
	variable i,j
	for(i=1;i<=numCells;i+=1)
		if(shape[i-1]>0)
			appendtograph /w=Times $"c"+num2str(i)+"_ker"
			appendmatrixcontour /w=Spaces $"c"+num2str(i)+"_pos"
			ModifyContour $"c"+num2str(i)+"_pos" labels=0,autoLevels={0.55,0.65,1}
			if(shape[i-1]==16)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(65535,16385,55749)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(65535,16385,55749)
			elseif(shape[i-1]==17)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(3,52428,1)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(3,52428,1)
			elseif(shape[i-1]==29)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(65535,65535,0)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(65535,65535,0)
			elseif(shape[i-1]==1)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(0,65535,65535)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(0,65535,65535)
			elseif(shape[i-1]==43)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(1,16019,65535)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(1,16019,65535)
			elseif(shape[i-1]==8)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(0,0,0)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(0,0,0)
			elseif(shape[i-1]==0)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(48059,48059,48059)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(48059,48059,48059)
			elseif(shape[i-1]==19)
				Modifygraph /w=Times rgb($"c"+num2str(i)+"_ker")=(65535,0,0)
				ModifyContour /w=Spaces $"c"+num2str(i)+"_pos" rgbLines=(65535,0,0)
			endif
		endif
	endfor
	modifygraph /w=Times lsize=2
	modifygraph /w=Spaces lsize=2
	ModifyGraph /w=Spaces width={Plan,1,bottom,left},height=0
end

function hide(num)
	variable num
	wave shape
	variable i
	for(i=0;i<numpnts(shape);i+=1)
		if(shape[i]>0)
			if(shape[i]==num)
				modifycontour /w=Spaces $"c"+num2str(i+1)+"_pos" autoLevels={0.55,0.65,0}
			endif
			if(num==100)
				modifycontour /w=Spaces $"c"+num2str(i+1)+"_pos" autoLevels={0.55,0.65,0}
			endif
		endif
	endfor
end

function show(num)
	variable num
	wave shape	
	variable i
	for(i=0;i<numpnts(shape);i+=1)
		if(shape[i]>0)
			if(shape[i]==num)
				modifycontour /w=Spaces $"c"+num2str(i+1)+"_pos" autoLevels={0.55,0.65,1}
			endif
			if(num==100)
				modifycontour /w=Spaces $"c"+num2str(i+1)+"_pos" autoLevels={0.55,0.65,1}
			endif
		endif
	endfor
	modifygraph /w=spaces lsize=2
end

function norm_ker()
	wave shape
	wave c1_ker
	make /o/n=(numpnts(c1_ker)*10) rd,yllw
	setscale /i x,leftx(c1_ker),rightx(c1_ker),rd,yllw
	variable i,j,k
	for(i=0;i<numpnts(shape);i+=1)
		if(shape[i]==19)
			wave cell=$"c"+num2str(i+1)+"_ker"
			rd+=cell(x)
			j+=1
		endif
		if(shape[i]==29)
			wave cell=$"c"+num2str(i+1)+"_ker"
			yllw+=cell(x)
			k+=1
		endif
	endfor
	rd/=j
	yllw/=k
	wavestats /q rd
	printf "%g, %g\r",v_minloc,v_maxloc
	wavestats /q yllw
	printf "%g, %g\r",v_minloc,v_maxloc
	killwaves /z rd,yllw
end

function Do_Mosaic()
	get_Mosaic_Intra(19)
	get_Mosaic_Intra(29)
	get_Mosaic_Intra(8)
	get_Mosaic_Inter(19,8)
	get_Mosaic_Inter(29,8)
	killwaves /z M1,cell_nums1,cell_nums2,cell_nums
end

function Do_Nearest()
	getNearIntra(19)
	getNearIntra(29)
	getNearIntra(8)
	getNearInter(19,8)
	getNearInter(29,8)
	killwaves /z cell_nums1,cell_nums2,cell_nums,Closest,Nearest
end

function get_Mosaic_Intra(which)
	variable which
	wave Shape
	duplicate /o shape cell_nums
	cell_nums=selectnumber(shape==which,NaN,p)
	sort cell_nums,cell_nums
	wavestats /q cell_nums
	deletepoints v_npnts,v_numNaNs,cell_nums
	if(v_npnts>1)
		get_Distance()
		get_Slope()
		get_Spacing()
		wave Distances,R1,R2
		duplicate /o Distances Mosaics
		Mosaics=Distances/(R1+R2)
		duplicate /o Mosaics $"Mosaic"+num2str(which)
	else
		make /o/n=0 $"Mosaic"+num2str(which)
	endif
end

function getNearIntra(which)
	variable which
	wave Shape
	duplicate /o shape cell_nums
	cell_nums=selectnumber(shape==which,NaN,p)
	sort cell_nums,cell_nums
	wavestats /q cell_nums
	deletepoints v_npnts,v_numNaNs,cell_nums
	if(v_npnts>1)
		getDistance(cell_nums,cell_nums)
		getSlope(cell_nums,closest)
		getSpacing(cell_nums,closest)
		wave Distances,R1,R2
		duplicate /o Distances Nearest
		Nearest=Distances/(R1+R2)
		duplicate /o Nearest $"Nearest"+num2str(which)
	else
		make /o/n=0 $"Nearest"+num2str(which)
	endif
end

function get_Mosaic_Inter(which1,which2)
	variable which1,which2
	wave Shape
	duplicate /o shape cell_nums
	cell_nums=selectnumber(shape==which1 || shape==which2,NaN,p)
	sort cell_nums,cell_nums
	wavestats /q cell_nums
	deletepoints v_npnts,v_numNaNs,cell_nums
	if(v_npnts>1)
		get_Distance()
		get_Slope()
		get_Spacing()
		wave Distances,R1,R2
		duplicate /o Distances Mosaics
		Mosaics=Distances/(R1+R2)
		duplicate /o Mosaics $"Mosaic"+num2str(which1)+num2str(which2)
	else
		make /o/n=0 $"Mosaic"+num2str(which1)+num2str(which2)
	endif
end

function get_Mosaic_Inter_a(which1,which2)
	variable which1,which2
	wave Shape
	duplicate /o shape cell_nums1,cell_nums2
	cell_nums1=selectnumber(shape==which1,NaN,p)
	cell_nums2=selectnumber(shape==which2,NaN,p)
	sort cell_nums2,cell_nums2
	wavestats /q cell_nums2
	deletepoints v_npnts,v_numNaNs,cell_nums2
	sort cell_nums1,cell_nums1
	wavestats /q cell_nums1
	deletepoints v_npnts,v_numNaNs,cell_nums1
	if(v_npnts>1)
		make /o/n=(numpnts(cell_nums1)+1) cell_nums
		cell_nums[1,numpnts(cell_nums)-1]=cell_nums1[p-1]
		make /o/n=(numpnts(cell_nums1)*numpnts(cell_nums2)) Mosaics
		variable i,j=numpnts(cell_nums1)
		for(i=0;i<numpnts(cell_nums2);i+=1)
			cell_nums[0]=cell_nums2[i]
			get_Distance()
			get_Slope()
			get_Spacing()
			wave Distances,R1,R2
			duplicate /o Distances M1
			M1=Distances/(R1+R2)
			Mosaics[i*j,(i+1)*j-1]=M1[p-(i*j)]
		endfor
		duplicate /o Mosaics $"Mosaic"+num2str(which1)+num2str(which2)
	else
		make /o/n=0 $"Mosaic"+num2str(which1)+num2str(which2)
	endif
end

function getNearInter(which1,which2)
	variable which1,which2
	wave Shape
	duplicate /o shape cell_nums1,cell_nums2
	cell_nums1=selectnumber(shape==which1,NaN,p)
	cell_nums2=selectnumber(shape==which2,NaN,p)
	sort cell_nums2,cell_nums2
	wavestats /q cell_nums2
	deletepoints v_npnts,v_numNaNs,cell_nums2
	sort cell_nums1,cell_nums1
	wavestats /q cell_nums1
	deletepoints v_npnts,v_numNaNs,cell_nums1
	if(v_npnts>1)
		getDistance(cell_nums1,cell_nums2)
		getSlope(cell_nums1,closest)
		getSpacing(cell_nums1,closest)
		wave Distances,R1,R2
		duplicate /o Distances Nearest
		Nearest=Distances/(R1+R2)
		duplicate /o Nearest $"Nearest"+num2str(which1)+num2str(which2)
	else
		make /o/n=0 $"Nearest"+num2str(which1)+num2str(which2)
	endif
end
	
function get_Distance()
	wave Parameters,cell_nums
	make /o/n=((numpnts(cell_nums)^2-numpnts(cell_nums))/2) Distances
	variable x_num,y_num
	variable i,j,k=0
	for(i=0;i<numpnts(cell_nums);i+=1)
		for(j=i+1;j<numpnts(cell_nums);j+=1)
			x_num=Parameters[cell_nums[i]][2]-Parameters[cell_nums[j]][2]
			y_num=Parameters[cell_nums[i]][4]-Parameters[cell_nums[j]][4]
			Distances[k]=sqrt(x_num^2+y_num^2)
			k+=1
		endfor
	endfor
end

function getDistance(cells1,cells2)
	wave cells1,cells2
	wave Parameters
	make /o/n=(numpnts(cells1)) Distances=1000,Closest
	variable x_num,y_num
	variable dis
	variable i,j
	for(i=0;i<numpnts(cells1);i+=1)
		for(j=0;j<numpnts(cells2);j+=1)
			x_num=Parameters[cells1[i]][2]-Parameters[cells2[j]][2]
			y_num=Parameters[cells1[i]][4]-Parameters[cells2[j]][4]
			dis=sqrt(x_num^2+y_num^2)
			if(dis<Distances[i] && i!= j)
				Distances[i]=sqrt(x_num^2+y_num^2)
				Closest[i]=cells2[j]
			endif
		endfor
	endfor
end

function get_slope()
	wave Parameters,cell_nums
	make /o/n=((numpnts(cell_nums)^2-numpnts(cell_nums))/2) Slopes
	variable x_num,y_num
	variable i,j,k=0
	for(i=0;i<numpnts(cell_nums);i+=1)
		for(j=i+1;j<numpnts(cell_nums);j+=1)
			x_num=Parameters[cell_nums[i]][2]-Parameters[cell_nums[j]][2]
			y_num=Parameters[cell_nums[i]][4]-Parameters[cell_nums[j]][4]
			Slopes[k]=y_num/x_num
			k+=1
		endfor
	endfor
end

function getSlope(cells,nears)
	wave cells,nears
	wave Parameters
	make /o/n=(numpnts(cells)) Slopes
	variable x_num,y_num
	variable i
	for(i=0;i<numpnts(cells);i+=1)
		x_num=Parameters[cells[i]][2]-Parameters[nears[i]][2]
		y_num=Parameters[cells[i]][4]-Parameters[nears[i]][4]
		Slopes[i]=y_num/x_num
	endfor
end

function get_Spacing()
	wave Parameters,cell_num
	make /o/n=((numpnts(cell_nums)^2-numpnts(cell_nums))/2) R1,R2
	variable cell
	variable i,j,k=0
	for(i=0;i<numpnts(cell_nums);i+=1)
		for(j=i+1;j<numpnts(cell_nums);j+=1)
			get_R(i,k,R1)
			get_R(j,k,R2)
			k+=1
		endfor
	endfor
end

function getSpacing(cells,nears)
	wave cells,nears
	wave Parameters
	make /o/n=(numpnts(cells)) R1,R2
	variable i
	for(i=0;i<numpnts(cells);i+=1)
		R1[i]=getR(cells,i)
		R2[i]=getR(nears,i)
	endfor
end

function get_R(which,num,wv)
	variable which,num
	wave wv
	wave cell_nums,Parameters,Slopes
	variable cell,sigx,sigy,Konst,Const,x_val,y_val
	cell=cell_nums[which]
	variable where=check(cell)
	sigx=Parameters[cell][3]
	sigy=Parameters[cell][5]
	Konst=2*(Parameters[cell][6]^2-1)*ln((where-Parameters[cell][0])/Parameters[cell][1])
	Const=(sigy^2+(sigx*Slopes[num])^2-2*Parameters[cell][6]*sigx*sigy*Slopes[num])/(sigx*sigy)^2
	x_val=sqrt(Konst/Const)
	y_val=Slopes[num]*x_val
	wv[num]=sqrt(x_val^2+y_val^2)
end

function getR(wv,which)
	wave wv
	variable which
	wave Parameters,Slopes
	variable cell,sigx,sigy,Konst,Const,x_val,y_val
	cell=wv[which]
	variable where=check(cell)
	sigx=Parameters[cell][3]
	sigy=Parameters[cell][5]
	Konst=2*(Parameters[cell][6]^2-1)*ln((where-Parameters[cell][0])/Parameters[cell][1])
	Const=(sigy^2+(sigx*Slopes[which])^2-2*Parameters[cell][6]*sigx*sigy*Slopes[which])/(sigx*sigy)^2
	x_val=sqrt(Konst/Const)
	y_val=Slopes[which]*x_val
	return sqrt(x_val^2+y_val^2)
end

function check(which)
	variable which
	variable cor,A0,z0
	wave Parameters
	z0=Parameters[which][0]
	A0=Parameters[which][1]
	cor=Parameters[which][6]
	return  z0+A0*exp(-1/2/(1-cor^2)*(1-cor))
end