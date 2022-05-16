###############################################################################################################
# SpeechRhythmExtractor.PSC
# Copyright (C) 2019, 2020, 2021, 2022 SILVA JR., Leonidas. & BARBOSA, Plinio Almeida. version 1.8
# SpeechRhythmExtractor (version 1.8)
# Script implemented by Leonidas SILVA JR. (State University of Paraiba / University of Campinas - Brazil) 
# & Plinio A. BARBOSA (University of Campinas - Brazil). 
# SpeechRhythmExtractor aims to build rhythmic multidimensional modellings taking vowel, consonant, 
# phonetic syllable, pause and higher units. Acoustic features are computed from a variety of (the classical) metrics 
# and prosodic-acoustic parameters.
# This script can be used in a cross-section of diifferent languages and dialects. 
# Audio/TEXTGRID files are required and have to be in the same directory of the script.
# Please, read the "UserManual" file to check metadata info, segmentation protocol and extracted parameters
#
# Derivative measures of F0, articulation rate, CPP and H1-H2 are based 
# in ProsodyDescriptorExtractor algorithm (BARBOSA, 2020).
# BARBOSA, P. ProsodyDescriptorExtractor. Computer program for Praat, 2020. 
# URL: <https://github.com/pabarbosa/prosody-scripts>.

#----------#----------#----------# Script under updating process #----------#----------#----------#----------#
# 	
#----------#----------#----------#### HOW TO CITE THIS SCRIPT ####----------#----------#----------#----------#
# SILVA JR., L.; BARBOSA, P. A. (2021). SpeechRhythmExtractor (version 1.02). Computer program for Praat. 
# URL: <https://github.com/leonidasjr/SpeechRhythmCode>.
#----------#----------#----------#----------#----------#----------#----------#----------#----------#
###############################################################################################################

## Getting started...

form set the input parameters
	comment Make sure all of the Audio & TextGrid files are the same folder of the script
	word Output_file 00_prosodic_features
	boolean voice_quality_parameters 0
	word Output_file_VQ 00_VQ_features
	comment Classify your group(s)
	choice Linguistic_target: 1
		button LANGUAGE
		button DIALECT
		button ACCENT
	comment Set Pitch parameters 
	choice Unit: 2
		button Hz
		button Semitones
	integer left_F0_threshold 75
	integer right_F0_threshold 500
	comment Tiers required for the parameters' computation
	integer VVtier 1
 	## integer PhoneTier (under updating...)
	integer VCtier 2
	## integer SentenceTier (under updating...)
	integer ChunkTier 3
	## integer ChunkTier 5
endform

## cleaning up Praat's objects window and appended information before workflow
numberOfSelectedObjects = numberOfSelected()
if numberOfSelectedObjects > 0
	select all
	Remove
endif

## assigned variables for using along the processes 
smooth_F0_threshold = 2
window = 0.03
f0step = 0.05
spectral_emphasis_threshold = 400

Create Strings as file list... audioDataList *.wav
numberOfFiles = Get number of strings

# .txt file that will contain the metadata, target and prosodic features of the corpus
fileOut$ = output_file$ + ".txt"
filedelete 'fileOut$'

fileappend 'fileOut$' AUDIOFILE 'tab$' 'linguistic_target$' 'tab$' SEX 'tab$' CHUNK 
...'tab$' percV 'tab$' percC 'tab$' deltaV 'tab$' deltaC 'tab$' deltaVC 'tab$' deltaS 
...'tab$' varcoV 'tab$' varcoC 'tab$' varcoVC 'tab$' varcoS 
...'tab$' rpviV 'tab$' rpviC 'tab$' rpviVC 'tab$' rpviS 
...'tab$' npviV 'tab$' npviC 'tab$' npviC 'tab$' npviS 
...'tab$' rrV 'tab$' rrC 'tab$' rrVC 'tab$' rrS 
...'tab$' viV 'tab$' viC 'tab$' viVC 'tab$' viS 
...'tab$' yardV 'tab$' yardC 'tab$' yardVC 'tab$' yardS 
...'tab$' f0median 'tab$' f0peak 'tab$' f0min 'tab$' f0sd 'tab$' f0skewness 'tab$' f0SAQ 'tab$' f0rate 'tab$' f0peak_rate 'tab$' f0min_rate 
...'tab$' df0mean 'tab$' df0mean_pos 'tab$' df0mean_neg 'tab$' df0sd 'tab$'df0sd_pos 'tab$' df0sd_neg 'tab$' df0skewness 
...'tab$' spect_emphasis 'tab$' sl_LTAS_breath 'tab$' sl_LTAS_alpha 'tab$' sl_LTAS_L1L0 'tab$' cvint 'tab$' jitter 'tab$' shimmer 'tab$' hnr 
...'tab$' pause_sd 'tab$' pause_meandur 'tab$' pause_rate 'tab$' silence_meandur 
...'tab$' speech_rate 'tab$' artic_rate 'newline$'

if voice_quality_parameters = 1
	# .txt file that will contain the metadata, target and voice quality features of the corpus
	fileOut2$ = output_file_VQ$ + ".txt"
	filedelete 'fileOut2$'
	fileappend 'fileOut2$' AUDIOFILE 'tab$' 'linguistic_target$' 'tab$' SEX 'tab$' CHUNK 'tab$' VOWEL 
	...'tab$' h1h2 'tab$' cpp 'newline$'
endif

for y from 1 to numberOfFiles
    select Strings audioDataList
    filename$ = Get string... y
    Read from file... 'filename$'
    soundFile$ = selected$ ("Sound")
    language$ = mid$(soundFile$,1,3)
    sex$ = mid$(soundFile$,4,3)
    textGridFile$ = soundFile$ + ".TextGrid"
	Read from file... 'textGridFile$'
	select TextGrid 'soundFile$'
  		  	
	#ZERO.ZERO-	############ voice quality parameters ##############
	if voice_quality_parameters = 1
		numberOfVowels = Get number of intervals... 'vCtier'

		for i from 2 to numberOfVowels - 1
			select TextGrid 'soundFile$'
			label_vowel$ = Get label of interval... 'vCtier' 'i'
 			if label_vowel$ = "V"
 				vowel$ = label_vowel$
 				start_time = Get start point... 'vCtier' 'i'
        		end_time = Get end point... 'vCtier' 'i'
        		midpoint = (start_time + end_time) / 2
        		timeinchunk = Get interval at time... 'chunkTier' 'midpoint'
        		chunk$ = Get label of interval... 'chunkTier' 'timeinchunk'
        		
        		select Sound 'soundFile$'
        		To Pitch... 0.0 'left_F0_threshold' 'right_F0_threshold'
        		select Pitch 'soundFile$'
        		mid_freq = Get quantile... 'start_time' 'end_time' 0.5 Hertz
        			if mid_freq = undefined
        				mid_freq = -1
        			endif
       			tleft = midpoint - 'window' / 2
        		tright = midpoint + 'window' / 2
        		
        		select Sound 'soundFile$'
        		Extract part... 'tleft' 'tright' rectangular 1.0 no
        		To Spectrum... yes
        			spect$ = selected$("Spectrum")
        		To PowerCepstrum
        			cpp = Get peak prominence... 60 340 Parabolic 0.001 0.0 Straight Robust
        		select Spectrum 'spect$'
        		To Ltas (1-to-1)
        			from_freq = 0
        			to_freq = mid_freq * 1.5
        			h1 = Get maximum... 'from_freq' 'to_freq' None
        		
        			from_freq = to_freq
        			to_freq = mid_freq * 2.5
        			h2 = Get maximum... 'from_freq' 'to_freq' None
        			h1h2 = h1 - h2
        		fileappend 'fileOut2$' 'soundFile$' 'tab$' 'language$' 'tab$' 'sex$' 'tab$' 'chunk$' 'tab$' 'vowel$' 
        		...'tab$' 'h1h2:2' 'tab$' 'cpp:2' 'newline$'
        	endif
		endfor
	endif
	
	# Computes all of the prosodic parameters along the chunks 
	select TextGrid 'soundFile$'
	nChunks = Get number of intervals... 'chunkTier'

	for x from 1 to nChunks
	start_time = Get start time of interval... 'chunkTier' 'x'
	end_time = Get end time of interval... 'chunkTier' 'x'
	chunk$ = Get label of interval... 'chunkTier' 'x'
		if chunk$ <> ""
			startChunk = Get starting point... 'chunkTier' 'x'
 			endChunk = Get end point... 'chunkTier' 'x'

			#ZERO.ONE- #########################------ Melodic and intensity parameters -----######################################################
			select Sound 'soundFile$'
 			Extract part... 'start_time' 'end_time' rectangular 1.0 yes
 				chunk_filename$ = selected$("Sound")
 				totaldur = Get total duration
 				begin = Get start time
				end = Get end time
			To Ltas... 100
				sl_ltas_low = Get slope... 300 800 50 300 energy
				sl_ltas_medium = Get slope... 0 1000 1000 4000 energy
				sl_ltas_high = Get slope... 0 1000 4000 8000 energy
			select Sound 'chunk_filename$'
			To Intensity... 'left_F0_threshold' 0.0 yes
				mint = Get mean... 0.0 0.0 energy
				sdint = Get standard deviation... 0 0
				cvint = 100 * sdint / mint
			
			select Sound 'chunk_filename$'
			To PointProcess (periodic, cc)... 'left_F0_threshold' 'right_F0_threshold'
			plus Sound 'chunk_filename$'
			To Ltas (only harmonics)... 50 0.0001 0.02 1.3
				lowmean = Get mean... 1.4 32 dB
				highmean = Get mean... 32 64.3 dB
				sPI = lowmean - highmean
			select PointProcess 'chunk_filename$'
				jitter = Get jitter (local)... 0.0 0.0 0.0001 0.02 1.3
				jitter = 100 * jitter
				plus Sound 'chunk_filename$'
					shimmer = Get shimmer (local)... 0 0 0.0001 0.02 1.3 1.6
					shimmer = 100 * shimmer

			select Sound 'chunk_filename$'
			To Spectrum... yes
				emphasis = Get band energy difference... 0 'spectral_emphasis_threshold' 0 0
			select Sound 'chunk_filename$'
			To Pitch... 0.0 'left_F0_threshold' 'right_F0_threshold'
			Smooth... 'smooth_F0_threshold'
		
			if unit = 2
				f0mean = Get mean... 'begin' 'end' semitones re 1 Hz
				f0median = Get quantile... 'begin' 'end' 0.5 semitones re 1 Hz
				f0peak = Get quantile... 'begin' 'end' 0.99 semitones re 1 Hz
				f0min = Get quantile... 'begin' 'end' 0.01 semitones re 1 Hz
				f0sd = Get standard deviation... 'begin' 'end' semitones
				f0skew = (f0mean - f0median)/f0sd
				f01Q = Get quantile... 'startChunk' 'endChunk' 0.25 semitones re 1 Hz
				f03Q = Get quantile... 'startChunk' 'endChunk' 0.75 semitones re 1 Hz
				f0SAQ = (f03Q - f01Q) / 2
			elsif unit = 1
				f0mean = Get mean... 'begin' 'end' Hertz
				f0median = Get quantile... 'begin' 'end' 0.5 Hertz
				f0peak = Get quantile... 'begin' 'end' 0.99 Hertz
				f0min = Get quantile... 'begin' 'end' 0.01 Hertz
				f0sd = Get standard deviation... 'begin' 'end' Hertz
				f0skew = (f0mean - f0median)/f0sd
				f01Q = Get quantile... 'begin' 'end' 0.25 Hertz
				f03Q = Get quantile... 'begin' 'end' 0.75 Hertz
				f0SAQ = (f03Q - f01Q)/2
				Smooth... 'smooth_F0_threshold'
				Interpolate
			endif

			To Matrix
 			To Sound (slice)... 1
			To PointProcess (extrema)... 1 yes no None
				ntones = Get number of points
				tonerate_max = ntones / totaldur

			###---###---###---###---###---###---###---###---###---###---###
			procedure melodic_rate
				select Sound 'soundFile$'
 				Extract part... 'start_time' 'end_time' rectangular 1.0 yes
 				chunk_filename$ = selected$("Sound")
				totaldur = Get total duration
 				begin = Get start time
				end = Get end time
				select Sound 'chunk_filename$'
				To Pitch... 0.0 'left_F0_threshold' 'right_F0_threshold'
				Smooth... 'smooth_F0_threshold'
				To Matrix
 				To Sound (slice)... 1
			endproc
			###---###---###---###---###---###---###---###---###---###---###

			@melodic_rate
			To PointProcess (extrema)... 1 yes yes None
				ntones_total = Get number of points
				tonerate_total = ntones_total / totaldur

			@melodic_rate
			To PointProcess (extrema)... 1 no yes None
				ntones_min = Get number of points
				tonerate_min = ntones_min / totaldur
		
			select Pitch 'chunk_filename$'
			#df0
			Down to PitchTier
				f0dur = Get total duration
				meandf0 = 0
				meandf0pos = 0 
				meandf0neg = 0 
		
				f0ant = Get value at time... 'startChunk'
				i = 1
				ineg = 0
				ipos = 0
				timef0 = f0step + 'startChunk'
			while timef0 <= (f0dur + startChunk)
				f0current = Get value at time... 'timef0'
				# Computes f0 discrete derivative, and its cumulative value
  				df0'i' = f0current - f0ant
  				if df0'i' > 0
   					meandf0pos = meandf0pos + df0'i'
   					ipos = ipos + 1
   					df0pos'ipos' = df0'i'
   				else
   					meandf0neg = meandf0neg + df0'i'
   					ineg = ineg + 1
   					df0neg'ineg' = df0'i'
   				endif
	 			meandf0 = meandf0 + df0'i'
  				f0ant = f0current
				timef0 = timef0 + f0step
				i = i + 1
			endwhile
			i = i - 1
			meandf0 = meandf0/i
			meandf0pos = meandf0pos/ipos
			meandf0neg = meandf0neg/ineg

			# Computes f0 discrete derivative standard deviation
			sdf0 = 0
			for j from 1 to i
 				sdf0 = sdf0 + (df0'j' - meandf0)*(df0'j' - meandf0)
			endfor
			sdf0 = sqrt(sdf0/(i - 1))
			
			sdf0pos = 0
			for j from 1 to ipos
				sdf0pos = sdf0pos + (df0pos'j' - meandf0pos)*(df0pos'j' - meandf0pos)
			endfor
			sdf0pos = sqrt(sdf0pos/(ipos - 1))

			sdf0neg = 0
			for j from 1 to ineg
				sdf0neg = sdf0neg + (df0neg'j' - meandf0neg)*(df0neg'j' - meandf0neg)
			endfor
			sdf0neg = sqrt(sdf0neg/(ineg - 1))
		
			# Computes f0 discrete derivative skewness
			skdf0 = 0
			for j from 1 to i
 				skdf0 = skdf0 + ((df0'j' - meandf0)/sdf0)^3
			endfor
			skdf0 = (i/((i - 1) * (i - 2))) * skdf0

		select Sound 'soundFile$'
		To Harmonicity (cc): 0.01, 40, 0.1, 1
		select Harmonicity 'soundFile$'
			hnr = Get mean... 'startChunk' 'endChunk'

		# Silence sucession descriptors
		select TextGrid 'soundFile$'
			nVC = Get interval at time... 'vCtier' 'endChunk'
			start = Get interval at time... 'vCtier' 'startChunk'
			tiniant = 0
			sSil = 0
			tzero = Get start point... 'vCtier' 2
			cpt = 0
		for i from start to nVC
  			label$ = Get label of interval... 'vCtier' 'i'
  			if label$ = "_" or label$ = "#" or label$ = "PAUSE" or label$ = "sp" or label$ = "<sp>"
   				cpt = cpt + 1
   				tini = Get start point... 'vCtier' 'i'
   				tfin = Get end point... 'vCtier' 'i'
   				dursil = round(('tfin'-'tini')*1000)
   				sSil = sSil + dursil
				tiniant = tini
			endif
		endfor
		meandursil = sSil/cpt

	#1- #################------ %V -----#################

	nVC = Get interval at time... 'vCtier' 'endChunk'
	start = Get interval at time... 'vCtier' 'startChunk'

	#nVC = Get number of intervals... 'vCtier'
	cptV = 0
	cptC = 0
	sVdur = 0
	sCdur = 0

	procedure VC_duration
    	for i from start to nVC - 1
 			label$ = Get label of interval... 'vCtier' 'i'
  			if label$ == "V"
    			cptV = cptV + 1
  	 			itime = Get starting point... 'vCtier' 'i'
  	 			ftime = Get end point... 'vCtier' 'i'
  	 			durV'cptV' = (ftime - itime)*1000
  	 			sVdur = sVdur + durV'cptV'
    		elsif label$  == "C"
        		cptC = cptC + 1
  	 			itime = Get starting point... 'vCtier' 'i'
  	 			ftime = Get end point... 'vCtier' 'i'
  	 			durC'cptC' = (ftime - itime)*1000
  	 			sCdur = sCdur + durC'cptC'
 			endif
    	endfor
	endproc

	call VC_duration

	percV = sVdur/(sVdur + sCdur)

	#2- #################------ %C -----#################

	percC = sCdur/(sVdur + sCdur)

	#3- #################------ DeltaV -----#################

	cptV = 0
	cptC = 0
	sVdur = 0
	sCdur = 0

	call VC_duration

	meanDurV = sVdur/cptV

	sdDurV = 0
	for i from 1 to cptV 
    	sdDurV = sdDurV + (durV'i' - meanDurV)*(durV'i' - meanDurV)
	endfor
	deltaV = sqrt(sdDurV/(cptV -1))


#4- #########################------ DeltaC -----##################################################

meanDurC = sCdur/cptC

sdDurC = 0
for i from 1 to cptC 
    sdDurC = sdDurC + (durC'i' - meanDurC)*(durC'i' - meanDurC)
endfor
deltaC = sqrt(sdDurC/(cptC -1))


#5- ########################------ DeltaVC -----###################################################

cptVC = 0
sVCdur = 0

procedure AllSegs_duration
   for i from start to nVC - 1
 	label$ = Get label of interval... 'vCtier' 'i'
  	if label$ <> ""
    	 cptVC = cptVC + 1
  	 itime = Get starting point... 'vCtier' 'i'
  	 ftime = Get end point... 'vCtier' 'i'
  	 durVC'cptVC' = (ftime - itime)*1000
  	 sVCdur = sVCdur + durVC'cptVC'
	endif
   endfor
endproc

call AllSegs_duration

meanDurVC = sVCdur/cptVC

sdDurVC = 0
for i from 1 to cptVC
    sdDurVC = sdDurVC + (durVC'i' - meanDurVC)*(durVC'i' - meanDurVC)
endfor
deltaVC = sqrt(sdDurVC/(cptVC -1))


#6- ########################------ Delta-S -----###################################################

nVV = Get interval at time... 'vVtier' 'endChunk'
startVV = Get interval at time... 'vVtier' 'startChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
sVVdur = 0

procedure Syl_duration
   for i from startVV to nVV - 1
	label$ = Get label of interval... 'vVtier' 'i'
	 if label$ == "VV"
  	  cptVV = cptVV + 1
  	  itime = Get starting point... 'vVtier' 'i'
  	  ftime = Get end point... 'vVtier' 'i'
  	  durVV'cptVV' = (ftime - itime)*1000
  	  sVVdur = sVVdur + durVV'cptVV'
  	endif
   endfor
endproc

call Syl_duration

meanDurVV = sVVdur/cptVV

sdDurVV = 0
for i from 1 to cptVV 
    sdDurVV = sdDurVV + (durVV'i' - meanDurVV)*(durVV'i' - meanDurVV)
endfor
deltaSyl = sqrt(sdDurVV/(cptVV -1))


#7- ########################------ VarcoV -----###################################################

varcoV = (deltaV)/(meanDurV)


#8- ########################------ VarcoC -----###################################################

varcoC = (deltaC)/(meanDurC)


#9- ########################------ VarcoVC -----##################################################

varcoVC = (deltaVC)/(meanDurVC)


#10- ########################------ Varco-S -----#################################################

varcoSyl = (deltaSyl)/(meanDurVV)


#11- ##################------ Raw Pairwise Variability Index (rPVI-V) -----#######################

nVC = Get interval at time... 'vCtier' 'endChunk'

#nVC = Get number of intervals... 'vCtier'
cptV = 0
sVdur = 0
cptC = 0
sCdur =0 

procedure VC_PVI
	for i from start to nVC - 2
 	label$ = Get label of interval... 'vCtier' 'i'
 	  if label$ == "V"
  	   cptV = cptV + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durV = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurV = (nextFtime - nextItime)*1000
  	   sVdur = sVdur + abs(durV - nextDurV)
 	  elsif label$ == "C"
  	   cptC = cptC + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durC = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurC = (nextFtime - nextItime)*1000
  	   sCdur = sCdur + abs(durC - nextDurC)
 	  endif
	endfor
endproc

call VC_PVI

rPVIV = sVdur/cptV


#12- ##################------ Raw Pairwise Variability Index (rPVI-C) -----#######################

rPVIC = sCdur/cptC


#13- ##################------ Raw Pairwise Variability Index (rPVI-VC) -----#######################

cptVC = 0
sVCdur = 0

procedure AllSegs_PVI
	for i from start to nVC - 2
 	label$ = Get label of interval... 'vCtier' 'i'
 	  if label$ <> ""
  	   cptVC = cptVC + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durVC = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurVC = (nextFtime - nextItime)*1000
  	   sVCdur = sVCdur + abs(durVC - nextDurVC)
	  endif
	endfor
endproc

call AllSegs_PVI

rPVIVC = sVCdur/cptVC


#14- ##################------ Raw Pairwise Variability Index (rPVI-S) -----#######################

nVV = Get interval at time... 'vVtier' 'endChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
sVVdur = 0

procedure Syl_PVI
	for i from startVV to nVV - 2
 	label$ = Get label of interval... 'vVtier' 'i'
 	  if label$ <> ""
  	   cptVV = cptVV + 1
  	   itime = Get starting point... 'vVtier' 'i'
  	   ftime = Get end point... 'vVtier' 'i'
  	   durVV = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vVtier' 'nextI'
  	   nextFtime = Get end point... 'vVtier' 'nextI'
  	   nextDurVV = (nextFtime - nextItime)*1000
  	   sVVdur = sVVdur + abs(durVV - nextDurVV)
	  endif
	endfor
endproc

call Syl_PVI

rPVIVV = sVVdur/cptVV


#15- ###################------ Normalized Pairwise Variability Index (nPVI-V) -----################

nVC = Get interval at time... 'vCtier' 'endChunk'

#nVC = Get number of intervals... 'vCtier'
cptV = 0
sVdur = 0
cptC = 0
sCdur = 0

procedure VC_nPVI
	for i from start to nVC - 2
 	label$ = Get label of interval... 'vCtier' 'i'
 	  if label$ == "V"
  	   cptV = cptV + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durV = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurV = (nextFtime - nextItime)*1000
  	   sVdur = sVdur + abs(durV - nextDurV)/((durV + nextDurV)/2)
 	  elsif label$ == "C"
  	   cptC = cptC + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durC = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurC = (nextFtime - nextItime)*1000
  	   sCdur = sCdur + abs(durC - nextDurC)/((durC + nextDurC)/2)
 	  endif
	endfor
endproc

call VC_nPVI

nPVIV = sVdur/cptV


#16- ###################------ Normalized Pairwise Variability Index (nPVI-C) -----################

nPVIC = sCdur/cptC


#17- ###################------ Normalized Pairwise Variability Index (nPVI-VC) -----################

cptVC = 0
sVCdur = 0

procedure AllSegs_nPVI
	for i from start to nVC - 2
 	label$ = Get label of interval... 'vCtier' 'i'
 	  if label$ <> ""
  	   cptVC = cptVC + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durVC = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurVC = (nextFtime - nextItime)*1000
  	   sVCdur = sVCdur + abs(durVC - nextDurVC)/((durVC + nextDurVC)/2)
	  endif
	endfor
endproc
call AllSegs_nPVI

nPVIVC = sVCdur/cptVC


#18- ###################------ Normalized Pairwise Variability Index (nPVI-S) -----################

nVV = Get interval at time... 'vVtier' 'endChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
sVVdur = 0

procedure Syl_nPVI
	for i from startVV to nVV - 2
 	label$ = Get label of interval... 'vVtier' 'i'
 	  if label$ <> ""
  	   cptVV = cptVV + 1
  	   itime = Get starting point... 'vVtier' 'i'
  	   ftime = Get end point... 'vVtier' 'i'
  	   durVV = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vVtier' 'nextI'
  	   nextFtime = Get end point... 'vVtier' 'nextI'
  	   nextDurVV = (nextFtime - nextItime)*1000
  	   sVVdur = sVVdur + abs(durVV - nextDurVV)/((durVV + nextDurVV)/2)
	  endif
	endfor
endproc

call Syl_nPVI

nPVIVV = sVVdur/cptVV


#19 -#######################------ Rhythm Ratio (RR-V) -----########################################

nVC = Get interval at time... 'vCtier' 'endChunk'
start = Get interval at time... 'vCtier' 'startChunk'

#nVC = Get number of intervals... 'vCtier'
cptV = 0
ratioV = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
   if label$ == "V"
         cptV = cptV + 1
         itime = Get starting point... 'vCtier' 'i'
         ftime = Get end point... 'vCtier' 'i'
         durV = (ftime - itime)*1000
         nextI = i + 1
         nextItime = Get starting point... 'vCtier' 'nextI' 
         nextFtime = Get end point... 'vCtier' 'nextI' 
         nextDurV = (nextFtime - nextItime)*1000
	
       if durV < nextDurV
   	 ratioV = ratioV + abs(durV/nextDurV)
 	else
   	 ratioV = ratioV + abs(nextDurV/durV)
       endif
   endif
endfor

rRV = (ratioV/cptV)*100


#20 -#######################------ Rhythm Ratio (RR-C) -----########################################

cptC = 0
ratioC = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
   if label$ == "C"
         cptC = cptC + 1
         itime = Get starting point... 'vCtier' 'i'
         ftime = Get end point... 'vCtier' 'i'
         durC = (ftime - itime)*1000
         nextI = i + 1
         nextItime = Get starting point... 'vCtier' 'nextI' 
         nextFtime = Get end point... 'vCtier' 'nextI' 
         nextDurC = (nextFtime - nextItime)*1000
	
       if durC < nextDurC
   	 ratioC = ratioC + abs(durC/nextDurC)
 	else
   	 ratioC = ratioC + abs(nextDurC/durC)
       endif
   endif
endfor


rRC = (ratioC/cptC)*100


#21 -#######################------ Rhythm Ratio (RR-VC) -----########################################

cptVC = 0
ratioVC = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
  if label$ <> ""
	 cptVC = cptVC + 1
	 itime = Get starting point... 'vCtier' 'i'
	 ftime = Get end point... 'vCtier' 'i'
   	 durVC = (ftime - itime)*1000
   	 nextI = i + 1
   	 nextItime = Get starting point... 'vCtier' 'nextI'
   	 nextFtime = Get end point... 'vCtier' 'nextI'
   	 nextDurVC = (nextFtime - nextItime)*1000

	if durVC < nextDurVC
   	 ratioVC = ratioVC +  abs(durVC/nextDurVC)
 	else
   	 ratioVC = ratioVC +  abs(nextDurVC/durVC)
        endif
   endif
endfor

rRVC = (ratioVC/cptVC)*100


#22 -#######################------ Rhythm Ratio (RR-S) -----########################################

nVV = Get interval at time... 'vVtier' 'endChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
ratioVV = 0

for i from startVV to nVV - 2
label$ = Get label of interval... 'vVtier' 'i'
	if label$ <> ""
		cptVV = cptVV + 1
   	 	itime = Get starting point... 'vVtier' 'i'
   	 	ftime = Get end point... 'vVtier' 'i'
   	 	durVV = (ftime - itime)*1000
   	 	nextI = i + 1
   	 	nextItime = Get starting point... 'vVtier' 'nextI'
   	 	nextFtime = Get end point... 'vVtier' 'nextI'
   	 	nextDurVV = (nextFtime - nextItime)*1000
		if durVV < nextDurVV
	   		 ratioVV = ratioVV +  abs(durVV/nextDurVV)
 		else
   	 		ratioVV = ratioVV +  abs(nextDurVV/durVV)
   	 	endif
   	 endif
endfor

rRS = (ratioVV/cptVV)*100


#23 -#######################------ Variability Index (VI-V) -----###################################

nVC = Get interval at time... 'vCtier' 'endChunk'
start = Get interval at time... 'vCtier' 'startChunk'

#nVC = Get number of intervals... 'vCtier'
cptV = 0
sVdur = 0
vIV = 0

for i from start to nVC - 2
 	label$ = Get label of interval... 'vCtier' 'i'
 	  if label$ == "V"
  	   cptV = cptV + 1
  	   itime = Get starting point... 'vCtier' 'i'
  	   ftime = Get end point... 'vCtier' 'i'
  	   durV = (ftime - itime)*1000
  	   nextI = i + 1
  	   nextItime = Get starting point... 'vCtier' 'nextI'
  	   nextFtime = Get end point... 'vCtier' 'nextI'
  	   nextDurV = (nextFtime - nextItime)*1000
	   sVdur = sVdur + durV
	   vIV = vIV + abs(durV - nextDurV)
 	  endif
endfor

meanDurV_VI = sVdur/cptV	
vIV = vIV/(cptV*meanDurV_VI)


#24 -#######################------ Variability Index (VI-C) -----###################################

cptC = 0
sCdur = 0
vIC = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
 	if label$ == "C"
         cptC = cptC + 1
         itime = Get starting point... 'vCtier' 'i'
         ftime = Get end point... 'vCtier' 'i'
         durC = (ftime - itime)*1000
         nextI = i + 1
         nextItime = Get starting point... 'vCtier' 'nextI' 
         nextFtime = Get end point... 'vCtier' 'nextI' 
         nextDurC = (nextFtime - nextItime)*100
	 sCdur = sCdur + durC
	   vIC = vIC + abs(durC - nextDurC)
 	  endif
endfor

meanDurC_VI = sCdur/cptC	
vIC = vIC/(cptV*meanDurC_VI)


#25 -#######################------ Variability Index (VI-VC) -----###################################

cptVC = 0
sVCdur = 0
vIVC = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
  	if label$ <> ""
	 cptVC = cptVC + 1
   	 itime = Get starting point... 'vCtier' 'i'
  	 ftime = Get end point... 'vCtier' 'i'
   	 durVC = (ftime - itime)*1000
   	 nextI = i + 1
   	 nextItime = Get starting point... 'vCtier' 'nextI'
   	 nextFtime = Get end point... 'vCtier' 'nextI'
   	 nextDurVC = (nextFtime - nextItime)*1000
	 sVCdur = sVCdur + durVC
	   vIVC = vIVC + abs(durVC - nextDurVC)
 	  endif
endfor

meanDurVC_VI = sVCdur/cptVC	
vIVC = vIVC/(cptVC*meanDurVC_VI)


#26 -#######################------ Variability Index (VI-S) -----###################################

nVV = Get interval at time... 'vVtier' 'endChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
sVVdur = 0
vIVV = 0

for i from startVV to nVV - 2
label$ = Get label of interval... 'vVtier' 'i'
	cptVV = cptVV + 1
	if label$ <> ""
   	 itime = Get starting point... 'vVtier' 'i'
   	 ftime = Get end point... 'vVtier' 'i'
   	 durVV = (ftime - itime)*1000
   	 nextI = i + 1
   	 nextItime = Get starting point... 'vVtier' 'nextI'
   	 nextFtime = Get end point... 'vVtier' 'nextI'
   	 nextDurVV = (nextFtime - nextItime)*1000
	 sVVdur = sVVdur + durVV
	   vIVV = vIVV + abs(durVV - nextDurVV)
 	  endif
endfor

meanDurVV_VI = sVVdur/cptVV
vIVV = vIVV/(cptVV*meanDurVV_VI)


#27 -#######################------ Yet Another Rhythm Determination (YARD-V) -----##################

nVC = Get interval at time... 'vCtier' 'endChunk'
start = Get interval at time... 'vCtier' 'startChunk'

#nVC = Get number of intervals... 'vCtier'
cptV = 0
szV = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
  if label$ == "V"
   cptV = cptV + 1
   itime = Get starting point... 'vCtier' 'i'
   ftime = Get end point... 'vCtier' 'i'
   durV'cptV' = (ftime - itime)*1000
   nextI = i + 1
   nextItime = Get starting point... 'vCtier' 'nextI' 
   nextFtime = Get end point... 'vCtier' 'nextI' 
   nextDurV'nextI' = (nextFtime - nextItime)*1000
   zdurV = (durV'cptV' - meanDurV)/deltaV
   znextDurV = (nextDurV'nextI' - meanDurV)/deltaV
   szV = szV + abs(zdurV - znextDurV)
  endif
endfor

yardV = szV/cptV


#28 -#######################------ Yet Another Rhythm Determination (YARD-C) -----##################

cptC = 0
szC= 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
  if label$ == "C"
   cptC = cptC + 1
   itime = Get starting point... 'vCtier' 'i'
   ftime = Get end point... 'vCtier' 'i'
   durC'cptC' = (ftime - itime)*1000
   nextI = i + 1
   nextItime = Get starting point... 'vCtier' 'nextI' 
   nextFtime = Get end point... 'vCtier' 'nextI' 
   nextDurC'nextI' = (nextFtime - nextItime)*1000
   zdurC = (durC'cptC' - meanDurC)/deltaC
   znextDurC = (nextDurC'nextI' - meanDurC)/deltaC
   szC = szC + abs(zdurC - znextDurC)
  endif
endfor

yardC = szC/cptC


#29 -#######################------ Yet Another Rhythm Determination (YARD-VC) -----##################

cptVC = 0
szVC = 0

for i from start to nVC - 2
label$ = Get label of interval... 'vCtier' 'i'
  if label$ <> ""
   cptVC = cptVC + 1
   itime = Get starting point... 'vCtier' 'i'
   ftime = Get end point... 'vCtier' 'i'
   durVC'cptVC' = (ftime - itime)*1000
   nextI = i + 1
   nextItime = Get starting point... 'vCtier' 'nextI'
   nextFtime = Get end point... 'vCtier' 'nextI'
   nextDurVC'nextI' = (nextFtime - nextItime)*1000
   zdurVC = (durVC'cptVC' - meanDurVC)/deltaVC
   znextDurVC = (nextDurVC'nextI' - meanDurVC)/deltaVC
   szVC = szVC + abs(zdurVC - znextDurVC)
  endif
endfor

yardVC = szVC/cptVC


#30 -#######################------ Yet Another Rhythm Determination (YARD-S) -----##################

nVV = Get interval at time... 'vVtier' 'endChunk'

#nVV = Get number of intervals... 'vVtier'
cptVV = 0
szVV = 0

for i from startVV to nVV - 2
label$ = Get label of interval... 'vVtier' 'i'
  if label$ == "VV"
   cptVV = cptVV + 1
   itime = Get starting point... 'vVtier' 'i'
   ftime = Get end point... 'vVtier' 'i'
   durVV'cptVV' = (ftime - itime)*1000
   nextI = i + 1
   nextItime = Get starting point... 'vVtier' 'nextI'
   nextFtime = Get end point... 'vVtier' 'nextI'
   nextDurVV'nextI' = (nextFtime - nextItime)*1000
   zdurVV = (durVV'cptVV' - meanDurVV)/deltaSyl
   znextDurVV = (nextDurVV'nextI' - meanDurVV)/deltaSyl
   szVV = szVV + abs(zdurVV - znextDurVV)
  endif
endfor

yardVV = szVV/cptVV

#31 -#######################------ Speech rate (srate) -----########################

srate = 1000/meanDurVV

#32 -#######################------ Articulation rate (artrate) -----##################

cptPAUSE = 0
sPAUSEdur = 0

startVC = Get interval at time... 'vCtier' 'startChunk'
nVC = Get number of intervals... 'vCtier'
for i from startVC to nVC - 1
label$ = Get label of interval... 'vCtier' 'i'
  if label$ == "#" or label$ == "PAUSE" or label$ == "_" or label$ == "sp" or label$ == "<sp>" or label$ == "sil" or label$ == ""
   cptPAUSE = cptPAUSE + 1
   start_pause = Get starting point... 'vCtier' 'i'
   end_pause = Get end point... 'vCtier' 'i'
   durPAUSE'cptPAUSE' = (end_pause - start_pause)*1000
   sPAUSEdur = sPAUSEdur + durPAUSE'cptPAUSE'
  endif
endfor

meanDurPAUSE = sPAUSEdur/cptPAUSE

cptVV = 0
sVVdur = 0

startVV = Get interval at time... 'vVtier' 'startChunk'
nVV = Get number of intervals... 'vVtier'
for i from startVV to nVV - 1
label$ = Get label of interval... 'vVtier' 'i'
  if label$ == "VV"
   cptVV = cptVV + 1
   itime = Get starting point... 'vVtier' 'i'
   ftime = Get end point... 'vVtier' 'i'
   durVV'cptVV' = (ftime - itime)*1000
   sVVdur = sVVdur + durVV'cptVV'
  endif
endfor

artrate = (cptVV/(sVVdur-sPAUSEdur))*1000

#33- #########################------ DeltaPAUSE -----##################################################

#meanDurPAUSE = sPAUSEdur/cptPAUSE

sdDurPAUSE = 0
for i from 1 to cptPAUSE
    sdDurPAUSE = sdDurPAUSE + (durPAUSE'i' - meanDurPAUSE)*(durPAUSE'i' - meanDurPAUSE)
endfor
deltaPAUSE = sqrt(sdDurPAUSE/(cptPAUSE -1))

#pausedur = sPAUSEdur/1000

pauserate = abs((cptPAUSE/(sVVdur))) * 1000
#pauserate = abs((cptPAUSE/(sPAUSEdur-sVVdur)))*1000

fileappend 'fileOut$' 'filename$' 'tab$' 'language$' 'tab$' 'sex$' 'tab$' 'chunk$' 
...'tab$' 'percV:2' 'tab$' 'percC:2' 'tab$' 'deltaV:1' 'tab$' 'deltaC:1' 'tab$' 'deltaVC:1' 'tab$' 'deltaSyl:2' 
...'tab$' 'varcoV:2' 'tab$' 'varcoC:2' 'tab$' 'varcoVC:2' 'tab$' 'varcoSyl:2' 
...'tab$' 'rPVIV:2' 'tab$' 'rPVIC:2' 'tab$' 'rPVIVC:2' 'tab$' 'rPVIVV:2' 
...'tab$' 'nPVIV:2' 'tab$' 'nPVIC:2' 'tab$' 'nPVIVC:2' 'tab$' 'nPVIVV:2'
...'tab$' 'rRV:2' 'tab$' 'rRC:2' 'tab$' 'rRVC:2' 'tab$' 'rRS:2' 
...'tab$' 'vIV:2' 'tab$' 'vIC:2' 'tab$' 'vIVC:2' 'tab$' 'vIVV:2' 
...'tab$' 'yardV:2' 'tab$' 'yardC:2' 'tab$' 'yardVC:2' 'tab$' 'yardVV:2' 
...'tab$' 'f0median:2' 'tab$' 'f0peak:2' 'tab$' 'f0min:2' 'tab$' 'f0sd:2' 'tab$' 'f0skew:2' 'tab$' 'f0SAQ:2' 'tab$' 'tonerate_total:2' 'tab$' 'tonerate_max:2' 'tab$' 'tonerate_min:2' 
...'tab$' 'meandf0:2' 'tab$' 'meandf0pos:2' 'tab$' 'meandf0neg:2' 'tab$' 'sdf0:2' 'tab$' 'sdf0pos:2' 'tab$' 'sdf0neg:2' 'tab$' 'skdf0:2' 
...'tab$' 'emphasis:2' 'tab$' 'sl_ltas_high:1' 'tab$' 'sl_ltas_medium:1' 'tab$' 'sl_ltas_low:1' 'tab$' 'cvint:2' 'tab$' 'jitter:2' 'tab$' 'shimmer:2' 'tab$' 'hnr:2' 
...'tab$' 'deltaPAUSE:2' 'tab$' 'meanDurPAUSE:2' 'tab$' 'pauserate:2' 'tab$' 'meandursil:2'
...'tab$' 'srate:2' 'tab$' 'artrate:2' 'newline$'

			endif
  		endif
 	endfor
endfor

select all
	minus Strings audioDataList
Remove
Read Table from tab-separated file... 'fileOut$'
View & Edit
if voice_quality_parameters = 1
	Read Table from tab-separated file... 'fileOut2$'
	View & Edit
endif
