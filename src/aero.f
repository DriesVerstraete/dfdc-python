C=========================================================================
C DFDC (Ducted Fan Design Code) is an aerodynamic and aeroacoustic design
C and analysis tool for aircraft with propulsors in ducted fan
C configurations.
C 
C This software was developed under the auspices and sponsorship of the
C Tactical Technology Office (TTO) of the Defense Advanced Research
C Projects Agency (DARPA).
C 
C Copyright (c) 2004, 2005, Booz Allen Hamilton Inc., All Rights Reserved
C
C This program is free software; you can redistribute it and/or modify it
C under the terms of the GNU General Public License as published by the
C Free Software Foundation; either version 2 of the License, or (at your
C option) any later version.
C 
C This program is distributed in the hope that it will be useful, but
C WITHOUT ANY WARRANTY; without even the implied warranty of
C MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
C General Public License for more details.
C 
C You should have received a copy of the GNU General Public License along
C with this program; if not, write to the Free Software Foundation, Inc.,
C 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
C
C Authors: Harold Youngren (guppy@maine.rr.com), Mark Drela (drela@mit.edu)
C Program Management: Brad Tousley, Paul Eremenko (eremenko@alum.mit.edu)
C
C=========================================================================
C
C--- Aero data stored for one or more radial aerodynamic sections
C   
C-- aero data quantities for each defined radial aerodynamic section
C  NAERO     Number of aerodynamic datasets defined (NAERO>=1)
C  XIAERO    Radial station r/R where aero dataset is defined
C  AERODATA  Aerodynamic definition of the blade section at XIAERO
C            AERODATA( 1,x) = A0 (angle of zero lift)
C            AERODATA( 2,x) = CLMAX (Max CL)
C            AERODATA( 3,x) = CLMIN (Min CL)
C            AERODATA( 4,x) = DCLDA (Incompressible 2-D lift curve slope)
C            AERODATA( 5,x) = DCLDA_STALL (2-D lift curve slope at stall)
C            AERODATA( 6,x) = DCL_STALL (CL increment, onset to full stall)
C            AERODATA( 7,x) = CDMIN (Minimum drag coefficient value)
C            AERODATA( 8,x) = CLDMIN (Lift at minimum drag value)
C            AERODATA( 9,x) = DCDCL2 (Parabolic drag param d(Cd)/dCL^2)
C            AERODATA(10,x) = CMCON (Incompressible 2-D pitching moment)
C            AERODATA(11,x) = REREF (reference Reynold's number)
C            AERODATA(12,x) = REXP (Reynold's number exponent Cd~Re^REXP)
C            AERODATA(13,x) = MCRIT (critical Mach #)
C            AERODATA(14,x) = TOC (thickness/chord)
C            AERODATA(15,x) = DCDCL2S (Scndary, annulus drag param d(Cd)/dCL^2)
C=========================================================================
C
C     Version 070-ES1
C     Philip Carter, Esotec Developments, February 2009
C     philip (at) esotec (dot) org
C
C     Changes from 0.70:
C
C     CL/CD plotting fixed (missing argument).
C     READ and WRIT commands fixed (LU).
C     FLIP command to toggle to/from neg-BGam parameters.
C     DISP formats repaired. Message when set for neg-BGam.
C     Interpolated A0 (AZERO) stored by GETCLCDCM.
C     Multi-Re plotting with constant Mach or vice-versa (AEROPLT2).
C     Modified plotting interface.
C     All plotting functionality duplicated in EDIT.
C     PLOTMACH and PLOTREYN subroutines to avoid code duplication.
C     HARD and ANNO fixed.
C     Disk index displayed with data for multi-disk cases.
C     Disk index added to plot titles for multi-disk cases.
C     Mach constant or Re constant written to plot legends.
C     Various fixes to control structure and cosmetics.
C
C=========================================================================
C
C

      SUBROUTINE SETIAERO
C--------------------------------------------------
C     Sets up indices referring to aero section for 
C     each radial station
C--------------------------------------------------
      INCLUDE 'DFDC.INC'
C
C--- Find lower index of aero data sections XIAERO(N) bounding XI=YRC/RTIP
      DO NR = 1, NROTOR
       DO I=1, NRC
        IAERO(I,NR) = 1
        DO N = 1, NAERO(NR)
         XI = YRC(I,NR)/RTIP(NR)
         IF(XIAERO(N,NR).LE.XI) THEN
           IAERO(I,NR) = N
         ENDIF
        END DO
       END DO
      END DO
      RETURN
      END



      SUBROUTINE GETAERO(NR,N,XISECT,A0,CLMAX,CLMIN,
     &                   DCLDA,DCLDA_STALL,DCL_STALL,
     &                   CDMIN,CLDMIN,DCDCL2,DCDCL2S,
     &                   CMCON,MCRIT,TOC,REREF,REXP)
C---------------------------------------------
C     Gets aero data from stored section array
C
C   AERODATA    Aerodynamic definition of the blade section at XIAERO
C               AERODATA( 1,x) = A0 (angle of zero lift)
C               AERODATA( 2,x) = CLMAX (Max CL)
C               AERODATA( 3,x) = CLMIN (Min CL)
C               AERODATA( 4,x) = DCLDA (Incompressible 2-D lift curve slope)
C               AERODATA( 5,x) = DCLDA_STALL (2-D lift curve slope at stall)
C               AERODATA( 6,x) = DCL_STALL (CL increment, onset to full stall)
C               AERODATA( 7,x) = CDMIN (Minimum drag coefficient value)
C               AERODATA( 8,x) = CLDMIN (Lift at minimum drag value)
C               AERODATA( 9,x) = DCDCL2 (Parabolic drag param d(Cd)/dCL^2)
C               AERODATA(10,x) = CMCON (Incompressible 2-D pitching moment)
C               AERODATA(11,x) = REREF (reference Reynold's number)
C               AERODATA(12,x) = REXP (Reynold's number exponent Cd~Re^REXP)
C               AERODATA(13,x) = MCRIT (critical Mach #)
C               AERODATA(14,x) = TOC (thickness/chord)
C               AERODATA(15,x) = DCDCL2S (Secondary, annulus drag param d(Cd)/dCL^2)
C---------------------------------------------
      INCLUDE 'DFDC.INC'
C
      IF(NR.LT.1 .OR. NR.GT.NROTOR) THEN
        WRITE(*,*) 'Error: blade index of aero section out of bounds'
        RETURN
      ENDIF
      IF(N.LT.1 .OR. N.GT.NAERO(NR)) THEN
        WRITE(*,*) 'Error: index of aero section out of bounds'
        RETURN
      ENDIF
C
      A0          = AERODATA( 1,N,NR)
      CLMAX       = AERODATA( 2,N,NR)
      CLMIN       = AERODATA( 3,N,NR)
      DCLDA       = AERODATA( 4,N,NR)
      DCLDA_STALL = AERODATA( 5,N,NR)
      DCL_STALL   = AERODATA( 6,N,NR)
      CDMIN       = AERODATA( 7,N,NR)
      CLDMIN      = AERODATA( 8,N,NR)
      DCDCL2      = AERODATA( 9,N,NR)
      CMCON       = AERODATA(10,N,NR)
      REREF       = AERODATA(11,N,NR)
      REXP        = AERODATA(12,N,NR)
      MCRIT       = AERODATA(13,N,NR)
      TOC         = AERODATA(14,N,NR)
      DCDCL2S     = AERODATA(15,N,NR)
      XISECT      = XIAERO(N,NR)
C
      RETURN
      END


      SUBROUTINE PUTAERO(NR,N,XISECT,A0,CLMAX,CLMIN,
     &                   DCLDA,DCLDA_STALL,DCL_STALL,
     &                   CDMIN,CLDMIN,DCDCL2,DCDCL2S,
     &                   CMCON,MCRIT,TOC,REREF,REXP)
C--------------------------------------------------------
C     Puts aero data into stored section array at index N
C
C   AERODATA    Aerodynamic definition of the blade section at XIAERO
C               AERODATA( 1,x) = A0 (angle of zero lift)
C               AERODATA( 2,x) = CLMAX (Max CL)
C               AERODATA( 3,x) = CLMIN (Min CL)
C               AERODATA( 4,x) = DCLDA (Incompressible 2-D lift curve slope)
C               AERODATA( 5,x) = DCLDA_STALL (2-D lift curve slope at stall)
C               AERODATA( 6,x) = DCL_STALL (CL increment, onset to full stall)
C               AERODATA( 7,x) = CDMIN (Minimum drag coefficient value)
C               AERODATA( 8,x) = CLDMIN (Lift at minimum drag value)
C               AERODATA( 9,x) = DCDCL2 (Parabolic drag param d(Cd)/dCL^2)
C               AERODATA(10,x) = CMCON (Incompressible 2-D pitching moment)
C               AERODATA(11,x) = REREF (reference Reynold's number)
C               AERODATA(12,x) = REXP (Reynold's number exponent Cd~Re^REXP)
C               AERODATA(13,x) = MCRIT (critical Mach #)
C               AERODATA(14,x) = TOC (thickness/chord)
C               AERODATA(15,x) = DCDCL2S (Secondary, annulus drag param d(Cd)/dCL^2)
C--------------------------------------------------------
      INCLUDE 'DFDC.INC'
C 
      IF(NR.LT.1 .OR. NR.GT.NRX) THEN
        WRITE(*,*) 'Error: blade index of aero section out of bounds'
        RETURN
      ENDIF
      IF(N.LT.1) THEN
        WRITE(*,*) 'Error: index of aero section out of bounds'
        RETURN
      ENDIF
      IF(N.GT.NAX) THEN
        WRITE(*,*) 'Too many aero sections defined...'
        RETURN
      ENDIF
C
      AERODATA( 1,N,NR) = A0
      AERODATA( 2,N,NR) = CLMAX
      AERODATA( 3,N,NR) = CLMIN
      AERODATA( 4,N,NR) = DCLDA
      AERODATA( 5,N,NR) = DCLDA_STALL
      AERODATA( 6,N,NR) = DCL_STALL
      AERODATA( 7,N,NR) = CDMIN  
      AERODATA( 8,N,NR) = CLDMIN
      AERODATA( 9,N,NR) = DCDCL2
      AERODATA(10,N,NR) = CMCON 
      AERODATA(11,N,NR) = REREF
      AERODATA(12,N,NR) = REXP
      AERODATA(13,N,NR) = MCRIT
      AERODATA(14,N,NR) = TOC
      AERODATA(15,N,NR) = DCDCL2S
      XIAERO(N,NR)      = XISECT
C
      RETURN
      END



      SUBROUTINE SORTAR(NS,S,W,NDIM)
C----------------------------------------------------
C---- sort arrays by S values
C     Orders data monotonically increasing in S(i)
C----------------------------------------------------
      DIMENSION S(NS), W(NDIM,NS)
      LOGICAL DONE
C
      DO IPASS=1, 500
        DONE = .TRUE.
        DO N=1, NS-1
          NP = N+1
          IF(S(NP).LT.S(N)) THEN
           TEMP  = S(NP)
           S(NP) = S(N)
           S(N)  = TEMP
           DO L = 1, NDIM
             TEMP    = W(L,NP)
             W(L,NP) = W(L,N)
             W(L,N)  = TEMP
           END DO
           DONE = .FALSE.
          ENDIF
        END DO
        IF(DONE) GO TO 10
      END DO
      STOP 'SORTAR failed'
C
 10   RETURN
      END ! SORTAR


C*************************************************************************
C  Interpolated aero section properties functions
C  These routines implement a functional representation of the 
C  blade aero properties (CL,CD,CM) vs ALFA
C*************************************************************************


      SUBROUTINE GETCLCDCM(NR,IS,XI,ALF,W,REY,SECSIG,SECSTAGR,
     &                     CLIFT,CL_ALF,CL_W,
     &                     CLMAX,CLMIN,DCL_STALL,STALLF,
     &                     CDRAG,CD_ALF,CD_W,CD_REY,
     &                     CMOM,CM_AL,CM_W)
C-------------------------------------------------------------
C     CL(alpha),
C      CD(alpha), 
C       CM(alpha) interpolation function for blade at station IS at XI=r/R
C-------------------------------------------------------------
      INCLUDE 'DFDC.INC'
      LOGICAL STALLF,STALLF2
C
      IF(XI.LT.0.0 .OR. XI.GT.1.0) THEN
        WRITE(*,*) 'Undefined section XI in GETCLCDCM ',XI
      ENDIF
C
C--- Check for installed aero data section index
      N = IAERO(IS,NR)
      IF(N.LT.1 .OR. N.GT.NAERO(NR)) THEN
C
       IF(NAERO(NR).GT.1) THEN
C--- Find lower index of aero data sections XIAERO(N) bounding XI
        DO N = 1, NAERO(NR)
         IF(XIAERO(N,NR).LE.XI) THEN
cc          write(*,*) 'getcl iaero= ',N,' is= ',is,xiaero(N),xi
           IAERO(IS,NR) = N
          ELSE
           GO TO 10
         ENDIF
        END DO
        WRITE(*,*) 'Aero section not found for station ',XI
       ENDIF
C
       N = 1
       IAERO(IS,NR) = N
      ENDIF
C
C--- Get section aero data from stored section array
 10   A0          = AERODATA( 1,N,NR)
      CLMAX       = AERODATA( 2,N,NR)
      CLMIN       = AERODATA( 3,N,NR)
      DCLDA       = AERODATA( 4,N,NR)
      DCLDA_STALL = AERODATA( 5,N,NR)
      DCL_STALL   = AERODATA( 6,N,NR)
      CDMIN       = AERODATA( 7,N,NR)
      CLDMIN      = AERODATA( 8,N,NR)
      DCDCL2      = AERODATA( 9,N,NR)
      CMCON       = AERODATA(10,N,NR)
      REREF       = AERODATA(11,N,NR)
      REXP        = AERODATA(12,N,NR)
      MCRIT       = AERODATA(13,N,NR)
      TOC         = AERODATA(14,N,NR)
      DCDCL2S     = AERODATA(15,N,NR)
      XISECT1     = XIAERO(N,NR)
C
C--- Get data for inner bounding aero section
      CALL CLCDCM(ALF,W,REY,VSO,SECSIG,SECSTAGR,
     &            CLIFT,CL_ALF,CL_W,STALLF,
     &            CDRAG,CD_ALF,CD_W,CD_REY,
     &            CMOM,CM_AL,CM_W,
     &            A0,CLMAX,CLMIN,DCLDA,DCLDA_STALL,DCL_STALL,
     &            CDMIN,CLDMIN,DCDCL2,CMCON,MCRIT,REREF,REXP,
     &            TOC,DCDCL2S)
C
C--- Check for another bounding section, if not we are done, 
C    if we have another section linearly interpolate data to station IS
      IF(N.LT.NAERO(NR)) THEN
        XISECT2 = XIAERO(N+1,NR)
        FRAC = (XI-XISECT1)/(XISECT2-XISECT1)
        IF(FRAC.LE.0.0 .OR. FRAC.GT.1.0) THEN
cc         write(*,*) 'CL n,is,xi,frac = ',n,is,xi(is),frac
        ENDIF
C
C--- A02 sustituted for A0 in the following (2 places),
C    to permit A0 interpolation for storage in AZERO
C
        A02         = AERODATA( 1,N+1,NR)
        CLMAX2      = AERODATA( 2,N+1,NR)
        CLMIN2      = AERODATA( 3,N+1,NR)
        DCLDA       = AERODATA( 4,N+1,NR)
        DCLDA_STALL = AERODATA( 5,N+1,NR)
        DCL_STALL2  = AERODATA( 6,N+1,NR)
        CDMIN       = AERODATA( 7,N+1,NR)
        CLDMIN      = AERODATA( 8,N+1,NR)
        DCDCL2      = AERODATA( 9,N+1,NR)
        CMCON       = AERODATA(10,N+1,NR)
        REREF       = AERODATA(11,N+1,NR)
        REXP        = AERODATA(12,N+1,NR)
        MCRIT       = AERODATA(13,N+1,NR)
        TOC         = AERODATA(14,N+1,NR)
        DCDCL2S     = AERODATA(15,N+1,NR)
C
C--- Get data for outer bounding aero section
        CALL CLCDCM(ALF,W,REY,VSO,SECSIG,SECSTAGR,
     &              CLIFT2,CL_ALF2,CL_W2,STALLF2,
     &              CDRAG2,CD_ALF2,CD_W2,CD_REY2,
     &              CMOM2,CM_AL2,CM_W2,
     &              A02,CLMAX2,CLMIN2,DCLDA,DCLDA_STALL,DCL_STALL2,
     &              CDMIN,CLDMIN,DCDCL2,CMCON,MCRIT,REREF,REXP,
     &              TOC,DCDCL2S)
C--- Interpolate aero data to blade station
        STALLF = STALLF .OR. STALLF2
        CLIFT  = (1.0-FRAC)*CLIFT  + FRAC*CLIFT2
        CL_ALF = (1.0-FRAC)*CL_ALF + FRAC*CL_ALF2
        CL_W   = (1.0-FRAC)*CL_W   + FRAC*CL_W2
        CLMAX  = (1.0-FRAC)*CLMAX  + FRAC*CLMAX2
        CLMIN  = (1.0-FRAC)*CLMIN  + FRAC*CLMIN2
        DCL_STALL = (1.0-FRAC)*DCL_STALL + FRAC*DCL_STALL2
C
        CMOM   = (1.0-FRAC)*CMOM   + FRAC*CMOM2
        CM_AL  = (1.0-FRAC)*CM_AL  + FRAC*CM_AL2
        CM_W   = (1.0-FRAC)*CM_W   + FRAC*CM_W2
C
        CDRAG  = (1.0-FRAC)*CDRAG  + FRAC*CDRAG2
        CD_ALF = (1.0-FRAC)*CD_ALF + FRAC*CD_ALF2
        CD_W   = (1.0-FRAC)*CD_W   + FRAC*CD_W2
        CD_REY = (1.0-FRAC)*CD_REY + FRAC*CD_REY2
        A0     = (1.0-FRAC)*A0     + FRAC*A02
      ENDIF
C
      AZERO(IS,NR) = A0
C
      RETURN
      END  !GETCLCDCM



      SUBROUTINE GETALF(NR,IS,XI,SECSIG,SECSTAGR,
     &                  CLIFT,W,ALF,ALF_CL,ALF_W,STALLF)
C------------------------------------------------------------
C     Inverse alpha(CL) function 
C     Uses Newton-Raphson iteration to get ALF from CL function
C------------------------------------------------------------
      INCLUDE 'DFDC.INC'
      LOGICAL STALLF
      DATA NITER / 10 /
      DATA EPS   / 1.0E-5 /
C
      STALLF = .FALSE.
C
C---HHY A0 is now an aero section property
      A0  = AERODATA(1,IS,NR)
      REY = 0.0
C
      ALF = A0 
      DO ITER=1, NITER
        CALL GETCLCDCM(NR,IS,XI,ALF,W,REY,SECSIG,SECSTAGR,
     &                 CLTEMP,CL_ALF,CL_W,
     &                 CLMAX,CLMIN,DCL_STALL,STALLF,
     &                 CDRAG,CD_ALF,CD_W,CD_REY,
     &                 CMOM,CM_AL,CM_W)
cc      IF(STALLF) GO TO 20
        DALF = -(CLTEMP-CLIFT)/CL_ALF
        ALF = ALF + DALF
        ALF_CL =   1.0/CL_ALF
        ALF_W  = -CL_W/CL_ALF
        IF(ABS(DALF).LT.EPS) RETURN
      END DO
C
   20 WRITE(*,*) 'GETALF: alpha(CL) function inversion failed'
c      write(*,*) 'is,clift  ',is,clift
c      write(*,*) 'abs(dalf) ',abs(dalf)
c      write(*,*) 'cl_alf    ',cl_alf
C
      RETURN
      END ! GETALF



C*************************************************************************
C  Basic aero section properties functions
C  These routines implement a functional representation of the 
C  blade section aero properties (CL,CD,CM) vs ALF
C*************************************************************************

      SUBROUTINE CLCDCM(ALF,W,REY,VSO,SECSIG,SECSTAGR,
     &                  CLIFT,CL_ALF,CL_W,STALLF,
     &                  CDRAG,CD_ALF,CD_W,CD_REY,
     &                  CMOM,CM_AL,CM_W,
     &                  A0,CLMAX,CLMIN,DCLDA,DCLDA_STALL,DCL_STALL,
     &                  CDMIN,CLDMIN,DCDCL2,CMCON,MCRIT,REREF,REXP,
     &                  TOC,DCDCL2S)
C------------------------------------------------------------
C     CL(alpha) function
C     Note that in addition to setting CLIFT and its derivatives
C     CLMAX and CLMIN (+ and - stall CL's) are set in this routine
C     In the compressible range the stall CL is reduced by a factor
C     proportional to Mcrit-Mach.  Stall limiting for compressible 
C     cases begins when the compressible drag added CDC > CDMstall
C------------------------------------------------------------
C     CD(alpha) function - presently CD is assumed to be a sum
C     of profile drag + stall drag + compressibility drag
C     In the linear lift range drag is CD0 + quadratic function of CL-CLDMIN
C     In + or - stall an additional drag is added that is proportional
C     to the extent of lift reduction from the linear lift value.
C     Compressible drag is based on adding drag proportional to 
C     (Mach-Mcrit_eff)^MEXP
C------------------------------------------------------------
C     CM(alpha) function - presently CM is assumed constant,
C     varying only with Mach by Prandtl-Glauert scaling
C------------------------------------------------------------
C
C      INCLUDE 'DFDC.INC'
      IMPLICIT REAL (M)
      LOGICAL STALLF
      DOUBLE PRECISION ECMIN, ECMAX
C
C---- Factors for compressibility drag model, HHY 10/23/00
C     Mcrit is set by user
C     Effective Mcrit is Mcrit_eff = Mcrit - CLMFACTOR*(CL-CLDmin) - DMDD
C     DMDD is the delta Mach to get CD=CDMDD (usually 0.0020)
C     Compressible drag is CDC = CDMFACTOR*(Mach-Mcrit_eff)^MEXP
C     CDMstall is the drag at which compressible stall begins
C
      CDMFACTOR = 10.0
      CLMFACTOR =  0.25
      MEXP      =  3.0
      CDMDD     =  0.0020
      CDMSTALL  =  0.1000
C
C---- Prandtl-Glauert compressibility factor
      MSQ   =   W*W/VSO**2
      MSQ_W = 2.0*W/VSO**2
      IF(MSQ.GE.1.0) THEN
       WRITE(*,*)
     &  'CLFUNC: Local Mach number limited to 0.99, was ', MSQ
       MSQ = 0.99
       MSQ_W = 0.
      ENDIF
      PGRT = 1.0 / SQRT(1.0 - MSQ)
      PGRT_W = 0.5*MSQ_W * PGRT**3
C
C---- Mach number and dependence on velocity
      MACH = SQRT(MSQ)
      MACH_W = 0.0
      IF(MACH.NE.0.0) MACH_W = 0.5*MSQ_W/MACH 
C
C------------------------------------------------------------
C--- Generate CLFACTOR for cascade effects from section solidity
      CLFACTOR = 1.0
      IF(SECSIG.GT.0.0) THEN
        CALL GETCLFACTOR(SECSIG,SECSTAGR,CLFACTOR)
      ENDIF
C
C------------------------------------------------------------
C--- Generate CL from dCL/dAlpha and Prandtl-Glauert scaling
      CLA     = DCLDA*PGRT  *(ALF-A0) * CLFACTOR
      CLA_ALF = DCLDA*PGRT            * CLFACTOR
      CLA_W   = DCLDA*PGRT_W*(ALF-A0) * CLFACTOR
C
Cccccccccc
C      WRITE(*,*)'CL Factor   ALF   A0   DCLDA  CLA'
C      WRITE(*,*) CLFACTOR,ALF,A0,DCLDA,CLA
c
CC--- Effective CLmax is limited by Mach effects
C    reduces CLmax to match the CL of onset of serious compressible drag
      CLMX = CLMAX
      CLMN = CLMIN
      DMSTALL  = (CDMSTALL/CDMFACTOR)**(1.0/MEXP)
      CLMAXM = MAX(0.0, (MCRIT+DMSTALL-MACH)/CLMFACTOR) + CLDMIN
      CLMAX  = MIN(CLMAX,CLMAXM)
      CLMINM = MIN(0.0,-(MCRIT+DMSTALL-MACH)/CLMFACTOR) + CLDMIN
      CLMIN  = MAX(CLMIN,CLMINM)
C
C--- CL limiter function (turns on after +-stall 
      ECMAX = DEXP( MIN(200.0D0,DBLE((CLA-CLMAX)/DCL_STALL)) )
      ECMIN = DEXP( MIN(200.0D0,DBLE((CLMIN-CLA)/DCL_STALL)) )
      CLLIM = DCL_STALL * DLOG( (1.0D0+ECMAX)/(1.0D0+ECMIN) )
      CLLIM_CLA = ECMAX/(1.0+ECMAX) + ECMIN/(1.0+ECMIN)
c
c      if(CLLIM.GT.0.001) then
c      write(*,999) 'cla,cllim,ecmax,ecmin ',cla,cllim,ecmax,ecmin
c      endif
c 999  format(a,2(1x,f10.6),3(1x,d12.6))
C
C--- Subtract off a (nearly unity) fraction of the limited CL function
C    This sets the dCL/dAlpha in the stalled regions to 1-FSTALL of that
C    in the linear lift range
      FSTALL = DCLDA_STALL/DCLDA
      CLIFT  = CLA     - (1.0-FSTALL)*CLLIM
      CL_ALF = CLA_ALF - (1.0-FSTALL)*CLLIM_CLA*CLA_ALF
      CL_W   = CLA_W   - (1.0-FSTALL)*CLLIM_CLA*CLA_W
C
      STALLF = .FALSE.
      IF(CLIFT.GT.CLMAX) STALLF = .TRUE.
      IF(CLIFT.LT.CLMIN) STALLF = .TRUE.
C
C
C------------------------------------------------------------
C--- CM from CMCON and Prandtl-Glauert scaling
      CMOM  = PGRT*CMCON
      CM_AL = 0.0
      CM_W  = PGRT_W*CMCON
C
C
C------------------------------------------------------------
C--- CD from profile drag, stall drag and compressibility drag 
C
C---- Reynolds number scaling factor
      IF(REY.LE.0) THEN
       RCORR = 1.0
       RCORR_REY = 0.0
      ELSE
       RCORR     = (REY/REREF)**REXP
       RCORR_REY =  REXP/REY
      ENDIF
C
C--- Include quadratic lift drag terms from airfoil and annulus
C
c      CDCL2 = DCDCL2 + DCDCL2S
      CDCL2 = DCDCL2  ! no chance of getting messed up...
C
C--- In the basic linear lift range drag is a function of lift
C    CD = CD0 (constant) + quadratic with CL)
      CDRAG  = (CDMIN + CDCL2*(CLIFT-CLDMIN)**2    ) * RCORR
      CD_ALF = (    2.0*CDCL2*(CLIFT-CLDMIN)*CL_ALF) * RCORR
      CD_W   = (    2.0*CDCL2*(CLIFT-CLDMIN)*CL_W  ) * RCORR
      CD_REY = CDRAG*RCORR_REY
C
C--- Post-stall drag added
      FSTALL = DCLDA_STALL/DCLDA
      DCDX    = (1.0-FSTALL)*CLLIM/(PGRT*DCLDA)
c      write(*,*) 'cla,cllim,fstall,pg,dclda ',cla,cllim,fstall,pg,dclda
      DCD     = 2.0* DCDX**2
      DCD_ALF = 4.0* DCDX * 
     &         (1.0-FSTALL)*CLLIM_CLA*CLA_ALF/(PGRT*DCLDA)
      DCD_W = 4.0* DCDX * 
     &       ( (1.0-FSTALL)*CLLIM_CLA*CLA_W/(PGRT*DCLDA)
     &          - DCD/PGRT*PGRT_W )
c      write(*,*) 'alf,cl,dcd,dcd_alf,dcd_w ',alf,clift,dcd,dcd_alf,dcd_w
C
C--- Compressibility drag (accounts for drag rise above Mcrit with CL effects
C    CDC is a function of a scaling factor*(M-Mcrit(CL))**MEXP
C    DMDD is the Mach difference corresponding to CD rise of CDMDD at MCRIT
      DMDD = (CDMDD/CDMFACTOR)**(1.0/MEXP)
      CRITMACH = MCRIT-CLMFACTOR*ABS(CLIFT-CLDMIN) - DMDD
      CRITMACH_ALF  = -CLMFACTOR*ABS(CL_ALF)
      CRITMACH_W    = -CLMFACTOR*ABS(CL_W)
      IF(MACH.LT.CRITMACH) THEN
       CDC     = 0.0
       CDC_ALF = 0.0
       CDC_W   = 0.0
      ELSE
       CDC = CDMFACTOR*(MACH-CRITMACH)**MEXP
       CDC_W   = MEXP*MACH_W*CDC/MACH - MEXP*CRITMACH_W  *CDC/CRITMACH
       CDC_ALF =                      - MEXP*CRITMACH_ALF*CDC/CRITMACH
      ENDIF
c      write(*,*) 'critmach,mach ',critmach,mach
c      write(*,*) 'cdc,cdc_w,cdc_alf ',cdc,cdc_w,cdc_alf
C
      FAC   = 1.0
      FAC_W = 0.0
C--- Although test data does not show profile drag increases due to Mach # 
C    you could use something like this to add increase drag by Prandtl-Glauert
C    (or any function you choose) 
cc      FAC   = PG
cc      FAC_W = PG_W
C--- Total drag terms
      CDRAG  = FAC*CDRAG              + DCD     + CDC
      CD_ALF = FAC*CD_ALF             + DCD_ALF + CDC_ALF
      CD_W   = FAC*CD_W + FAC_W*CDRAG + DCD_W   + CDC_ALF
      CD_REY = FAC*CD_REY
C
      RETURN
      END ! CLCDCM



      SUBROUTINE CHKLIM(N,NSTRT,NEND,F,FMAX)
C--- Get starting and end index for array values F(i) < FMAX
      DIMENSION F(N)
      NSTRT = 1
      NEND  = N
C--- Look for first point where F(i)<FMAX
      DO I=1,N
          IF(F(I).LT.FMAX) GO TO 10
      END DO
 10   NSTRT = MAX(I-1,1)
C--- Look for last point where F(i)<FMAX
      DO I=N,1,-1
          IF(F(I).LT.FMAX) GO TO 20
      END DO
 20   NEND = MIN(I+1,N)
C
      RETURN
      END



      SUBROUTINE OPFILE(LU,FNAME)
      CHARACTER*(*) FNAME
C
      CHARACTER*4 COMAND
      CHARACTER*128 COMARG,TMP
      CHARACTER*1 ANS, DUMMY
C
C---- get filename if it hasn't been already specified
      IF(FNAME.EQ.' ') CALL ASKS('Enter output filename^',FNAME)
C
C---- try to open file
      OPEN(LU,FILE=FNAME,STATUS='OLD',ERR=50)
C
C---- file exists... ask how to proceed
      NF = INDEX(FNAME,' ') - 1
      TMP = 'File  '// FNAME(1:NF)//
     &      '  exists.  Overwrite / Append / New file ?^'
      CALL ASKC(TMP,COMAND,COMARG)
      ANS = COMAND(1:1)
C
C---- ask again if reply is invalid
      IF(INDEX('OoAaNn',ANS).EQ.0) THEN
        CALL ASKC(' O / A / N  ?^',COMAND,COMARG)
        ANS = COMAND(1:1)
C
        IF(INDEX('OoAaNn',ANS).EQ.0) THEN
C------- Still bad reply. Give up asking and just return
         WRITE(*,*) 'No action taken'
         RETURN
        ENDIF
      ENDIF
C
C---- at this point, file is open and reply is valid
      IF    (INDEX('Oo',ANS) .NE. 0) THEN
C------ go to beginning of file to overwrite
        REWIND(LU)
        GO TO 60
      ELSEIF(INDEX('Aa',ANS) .NE. 0) THEN
C------ go to end of file to append
        DO K=1, 12345678
          READ(LU,1000,END=40) DUMMY
 1000     FORMAT(A)
        ENDDO
 40     BACKSPACE(LU)
        GOTO 60
      ELSE
C------ new file... get filename from command argument, or ask if not supplied
        FNAME = COMARG
        IF(FNAME(1:1).EQ.' ') CALL ASKS('Enter output filename^',FNAME)
      ENDIF
C
C---- at this point, file FNAME is new or is to be overwritten
 50   OPEN(LU,FILE=FNAME,STATUS='UNKNOWN',ERR=90)
      REWIND(LU)
C
 60   RETURN
C
 90   WRITE(*,*) 'Bad filename.'
      RETURN
      END ! OPFILE


      SUBROUTINE GETCLFACTOR(SIGMA,STAGGER,CLFACTOR)
C------------------------------------------------------------
C     Calculates multi-plane cascade effect on lift slope as a
C     function of solidity and stagger angle
C
C     Input:  SIGMA      solidity = Bc/(2*pi*r)
C             STAGGER    stagger angle (from axis to chordline, in rads)
C 
C     Output:  CLFACTOR  CLmultiplane/CL2D factor
C
C     Implements table-driven quadratic fit to Figure 6-29 in 
C     Wallis, Axial Flow Fans and Ducts.
C------------------------------------------------------------
      PARAMETER (PI=3.1415926535897932384)
      PARAMETER (DTR=PI/180.)
C
      DIMENSION X(11), A0(11), A1(11), A2(11)
C---- Table of quadratic fit coefficients
      DATA X      / 0.5, 
     &              0.6, 
     &              0.7, 
     &              0.8, 
     &              0.9, 
     &              1.0,
     &              1.1, 
     &              1.2, 
     &              1.3, 
     &              1.4, 
     &              1.5 /
      DATA A0     / 0.4755, 
     &              0.5255, 
     &              0.5722, 
     &              0.6142, 
     &              0.6647, 
     &              0.7016, 
     &              0.7643, 
     &              0.8302, 
     &              0.8932, 
     &              0.9366, 
     &              0.9814 /
      DATA A1     / -0.367495, 
     &              -0.341941, 
     &              -0.300058, 
     &              -0.255883, 
     &              -0.200593, 
     &              -0.114993, 
     &              -0.118602, 
     &              -0.130921, 
     &              -0.133442, 
     &              -0.077980, 
     &              -0.123071 /
      DATA A2     /  0.489466, 
     &               0.477648, 
     &               0.453027, 
     &               0.430048, 
     &               0.381462, 
     &               0.310028, 
     &               0.298309, 
     &               0.285309, 
     &               0.263084, 
     &               0.184165, 
     &               0.251594 /
C
      CLFACTOR = 1.0
      IF(SIGMA.LE.0.6) RETURN
C
C---- Interpolate quadratic fit coefficients by 1/solidity
      SIGI = 1.0/SIGMA
      CALL SEVLIN(SIGI,A0,X,11,AA0,DAA0)
      CALL SEVLIN(SIGI,A1,X,11,AA1,DAA1)
      CALL SEVLIN(SIGI,A2,X,11,AA2,DAA2)
C
C---- Only valid for stagger 20deg to 90deg, 
C     Limit low stagger to 20deg value to give constant lift ratio below that
      STAGR = STAGGER
      IF(STAGR.LT.20.0*DTR) STAGR = 20.0*DTR
      IF(STAGR.GT.90.0*DTR) STAGR = 90.0*DTR
C
C---- Quadratic fit for CLFACTOR at this SIGMA as function of STAGGER
      CLFACTOR = AA0 + AA1*STAGR + AA2*STAGR*STAGR
C---- maximum value of lift ratio should be limited to 1.0
      CLFACTOR = MIN(1.0,CLFACTOR)
C
      RETURN
      END


C
C--- New subroutines since 0.70 -----------------------------------
C
      SUBROUTINE GETAFNAME(AFNAME,NAME,NR,NSEC)
      CHARACTER*80 NAME,AFNAME
      CHARACTER TNUM(9)*1
      DATA TNUM / '1','2','3','4','5','6','7','8','9' /
C
      L=LEN(NAME)
      DO J=L,1,-1
         IF(NAME(J:J).NE.' ')THEN
            L=J
            GO TO 10
         END IF
      ENDDO
 10   AFNAME=NAME(1:L) //': Disk '// TNUM(NR)//': Sec '//TNUM(NSEC)
C
      RETURN
      END  ! GETAFNAME
C
C--------------------------------------------------------------------
C