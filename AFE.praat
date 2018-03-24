##########################################################
#                                                        #
#               ___          ___       ___               #
#              /\  \        /\__\     /\__\              #
#             /::\  \      /:/ _/_   /:/ _/_             #
#            /:/\:\  \    /:/ /\__\ /:/ /\__\            #
#           /:/ /::\  \  /:/ /:/  //:/ /:/ _/_           #
#          /:/_/:/\:\__\/:/_/:/  //:/_/:/ /\__\          #
#          \:\/:/  \/__/\:\/:/  / \:\/:/ /:/  /          #
#           \::/__/      \::/__/   \::/_/:/  /           #
#            \:\  \       \:\  \    \:\/:/  /            #
#             \:\__\       \:\__\    \::/  /             #
#              \/__/        \/__/     \/__/              #
#                                                        #
#                        AFE.praat                       #
#               Acoustic Feature Extractor               #
#                                                        #
#                                      Sung Hah Hwang    #
#                          Written on: August 5, 2017    #
#                     Last updated on: March 24, 2018    #
#                                                        #
##########################################################


## Form (GUI)
form Acoustic Feature Extractor
  comment [ ACOUSTIC FEATURE EXTRACTOR ]
  comment This script extracts acoustic features from sound files with or without TextGrids

  comment ⦿ Directory of sound and TextGrid files (with trailing slash: '/'):
    text Directory /Users/sunghah/readSpeech/

    word Sound_extension_(with_dot) .wav

  comment ⦿ Full path to output result file:
    text ResultFile /Users/sunghah/readSpeech/result.txt

  comment ⦿ Specify which tier (number) to use in TextGrids:
    positive TierNumber 1

  comment ⦿ Extract without TextGrid (e.g., each sound file contains one vowel):
    boolean No_TextGrid

  comment ⦿ Target phonemes:
    choice Target: 1
      button All phonemes
      button Specified phoneme set
  comment ⦿ Specify phonemes of interest below (separated by comma without space):
    word Phoneme_set aa,ee,ii,oo,uu

  comment ⦿ Split each segment into chunks of:
    positive Chunks 3

  comment ⦿ Acoustic features to extract:
    boolean Duration 1
    boolean Formants 1
    boolean Pitch 1
    boolean Intensity 1
    boolean H1_-_H2
    boolean H1_-_A1,_H1_-_A2,_H1_-_A3
    boolean sd,_skewness,_kurtosis,_COG
endform


## Using feature array to improve readability
feature["duration"] = 'Duration'
feature["formants"] = 'Formants'
feature["pitch"] = 'Pitch'
feature["intensity"] = 'Intensity'
feature["h1_minus_h2"] = 'H1_-_H2'
feature["h1_minus_a123"] = 'H1_-_A1,_H1_-_A2,_H1_-_A3'
feature["sd_skewness_kurtosis_COG"] = 'sd,_skewness,_kurtosis,_COG'

## Exit if no feature is selected
if (feature["duration"] = 0) and
  ... (feature["formants"] = 0) and
  ... (feature["pitch"] = 0) and
  ... (feature["intensity"] = 0) and
  ... (feature["h1_minus_h2"] = 0) and
  ... (feature["h1_minus_a123"] = 0) and
  ... (feature["sd_skewness_kurtosis_COG"] = 0)
  exitScript: "No features are selected. Please select feature(s) to extract."
endif

## Check if another file exists by the name of the result file
if fileReadable(resultFile$)
  pause File named 'resultFile$'
  ... exists in specified location. Do you want to overwrite it?
  filedelete 'resultFile$'
endif

## Create file lists of sound and TextGrid files
Create Strings as file list... sound_list 'directory$'*'sound_extension$'
Create Strings as file list... textgrid_list 'directory$'*.TextGrid

## Check number of sound and TextGrid files
select Strings sound_list
numFiles = Get number of strings

select Strings textgrid_list
num_tg = Get number of strings

if numFiles = 0
  exitScript: "No sound files found in the specified directory: 'directory$'"
endif

if num_tg = 0
  pause No TextGrid files found in the specified directory. Do you want to continue?
endif

if numFiles <> num_tg
  pause The numbers of sound files and textgrids do not match. Do you want to continue?
endif

# Jitter will be added for more accurate measurements
jitter = 0.2


################################################################################
## Print statistics to Praat Info window
################################################################################


clearinfo

# Delimiter
delim$ = "==================================================
...=================================================="

file_count = 0

startdate$ = date$()
printline Job started on: 'startdate$''newline$'
printline Working directory:'tab$''directory$'
printline Result file path:'tab$''resultFile$'
printline 'delim$'

printline Number of Sound files:'tab$''tab$''numFiles'
printline Number of TextGrid files:'tab$''num_tg'

if no_TextGrid = 1
  printline 'tab$'- [ No TextGrid ] option selected
else
  printline 'tab$'- Using Tier number:'tab$''tierNumber'
endif

printline Number of Chunks:'tab$''tab$''chunks'
printline 'delim$'

printline Selected features:

if feature["duration"] = 1
  printline 'tab$''tab$''tab$' Duration
endif

if feature["formants"] = 1
  printline 'tab$''tab$''tab$' Formants
endif

if feature["pitch"] = 1
  printline 'tab$''tab$''tab$' Pitch
endif

if feature["intensity"] = 1
  printline 'tab$''tab$''tab$' Intensity
endif

if feature["h1_minus_h2"] = 1
  printline 'tab$''tab$''tab$' H1 - H2
endif

if feature["h1_minus_a123"] = 1
  printline 'tab$''tab$''tab$' H1 - A1, H1 - A2, H1 - A3
endif

if feature["sd_skewness_kurtosis_COG"] = 1
  printline 'tab$''tab$''tab$' sd, skewness, kurtosis, COG
endif

printline 'delim$'


################################################################################
## Write header in result file
################################################################################


if no_TextGrid = 1
  header$ = "filename,"
else
  header$ = "filename,left,phoneme,right,"
endif

if feature["duration"] = 1
  header$ = "'header$'start,end,duration,"
endif

if feature["formants"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'f1_ch'k$',f2_ch'k$',f3_ch'k$',f4_ch'k$',"
  endfor
  # Settings for formant extraction
  window_length = 0.025
  number_formants = 5
  f1ref = 500
  f2ref = 1485
  f3ref = 2450
  f4ref = 3550
  f5ref = 4650
  maximum_formant = 5500
  # num_tracks = 3
  freqcost = 1
  bwcost = 1
  transcost = 1
endif

if feature["pitch"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'pitch_ch'k$',"
  endfor
endif

if feature["intensity"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'intensity_ch'k$',"
  endfor
  # Set minimum pitch value
  minimum_pitch = 100
endif

if feature["h1_minus_h2"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'h1_minus_h2_ch'k$',"
  endfor
endif

if feature["h1_minus_a123"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'h1-a1_ch'k$',h1-a2_ch'k$',h1-a3_ch'k$',"
  endfor
endif

if feature["sd_skewness_kurtosis_COG"] = 1
  for k from 1 to chunks
    k$ = string$(k)
    header$ = "'header$'sd_ch'k$',skewness_ch'k$',kurtosis_ch'k$',COG_ch'k$',"
  endfor
endif

# Delete the trailing comma in header and write to file
len = length(header$)
header$ = mid$(header$, 1, len-1)
fileappend 'resultFile$' 'header$''newline$'


################################################################################
## Check if ... [no_TextGrid] = 1
##           or [target] = 1
##           or [target] = 2
##                           and start extraction
################################################################################


################################################################################
## Extraction without TextGrid
################################################################################


if no_TextGrid = 1

  for iFile from 1 to numFiles
    # Read in a sound file
    select Strings sound_list
    soundFile$ = Get string... iFile
    # nowarn Read from file... 'directory$''soundFile$'
    Read from file... 'directory$''soundFile$'

    # Get filename without extension
    dot_idx = rindex(soundFile$, ".")
    name$ = left$(soundFile$, (dot_idx - 1))

    # Resample sound file if needed
    if (feature["duration"] = 1) and
      ... (feature["formants"] = 0) and
      ... (feature["pitch"] = 0) and
      ... (feature["intensity"] = 0) and
      ... (feature["h1_minus_h2"] = 0) and
      ... (feature["h1_minus_a123"] = 0) and
      ... (feature["sd_skewness_kurtosis_COG"] = 0)
      soundObj = selected("Sound")
    else
      Resample... 16000 50
      soundObj = selected("Sound")
    endif

    # Create pitch object
    if (feature["pitch"] = 1) or
      ... (feature["h1_minus_h2"] = 1) or
      ... (feature["h1_minus_a123"] = 1)
      select 'soundObj'
      To Pitch... 0 50 600
      pitch_tracking = selected("Pitch")
      Interpolate
      Rename... 'name$'_interpolated
      pitch_interpolated = selected("Pitch")
    endif

    # Create intensity object
    if feature["intensity"] = 1
      select 'soundObj'
      To Intensity... minimum_pitch 0.0 yes
      intensity_tracking = selected("Intensity")
    endif

    # Start building resultLine; will write once at the end of the loop
    resultLine$ = "'name$',"

    # Get start and end time
    start = Get start time
    end = Get end time
    dur = end - start


    # Extract features: [start, end, duration]
    if feature["duration"] = 1
      resultLine$ = "'resultLine$''start','end','dur',"
    endif


    # Extract features: [f1, f2, f3, f4]
    if feature["formants"] = 1
      select 'soundObj'
      To Formant (burg)... 0 number_formants maximum_formant window_length 50
      Rename... 'name$'_beforeTracking
      formant_beforeTracking = selected("Formant")

      min_formants = Get minimum number of formants
      if min_formants > 3
        Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      elsif min_formants > 2
        Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      else
        Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      endif

      Rename... 'name$'_afterTracking
      formant_afterTracking = selected("Formant")

      # Extract features by chunk
      for counter from 1 to 'chunks'
        quotient = dur / chunks
        ch_start = quotient * (counter - 1)
        ch_end = ch_start + quotient

        select 'formant_afterTracking'
        f1 = Get mean... 1 ch_start ch_end Hertz
        f2 = Get mean... 2 ch_start ch_end Hertz

        if min_formants > 3
          f3 = Get mean... 3 ch_start ch_end Hertz
          f4 = Get mean... 4 ch_start ch_end Hertz
        elsif min_formants > 2
          f3 = Get mean... 3 ch_start ch_end Hertz
          f4 = 0
        else
          f3 = 0
          f4 = 0
        endif

        resultLine$ = "'resultLine$''f1','f2','f3','f4',"
      endfor

      plus 'formant_beforeTracking'
      Remove
    endif


    # Extract features: [pitch]
    if feature["pitch"] = 1
      # Extract features by chunk
      for counter from 1 to 'chunks'
        quotient = dur / chunks
        ch_start = quotient * (counter - 1)
        ch_end = ch_start + quotient

        select 'pitch_interpolated'
        pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

        if pitch_val = undefined
          pitch_val = 0
        endif

        resultLine$ = "'resultLine$''pitch_val',"
      endfor
    endif


    # Extract features: [intensity]
    if feature["intensity"] = 1
      for counter from 1 to 'chunks'
        quotient = dur / chunks
        ch_start = quotient * (counter - 1)
        ch_end = ch_start + quotient

        select 'intensity_tracking'
        int = Get mean... start+quotient*(counter-1) start+quotient*counter dB

        resultLine$ = "'resultLine$''int',"
      endfor
    endif


    # Extract features: [H1 - H2]
    if feature["h1_minus_h2"] = 1
      select 'soundObj'

      Extract part... start end "rectangular" 1 "no"
      extractedObj = selected("Sound")

      To Formant (burg)... 0 number_formants maximum_formant window_length 50
      Rename... 'name$'_beforeTracking
      formant_beforeTracking = selected("Formant")

      no_formants = 0
      min_formants = Get minimum number of formants
      if min_formants > 3
        Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      elsif min_formants > 2
        Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      elsif min_formants > 1
        Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      else
        no_formants = 1
      endif

      if no_formants = 1
        h1_minus_h2 = 0

        for counter from 1 to 'chunks'
          resultLine$ = "'resultLine$''h1_minus_h2',"
        endfor

        select 'formant_beforeTracking'
        plus 'extractedObj'
        Remove

      else
        Rename... 'name$'_afterTracking
        formant_afterTracking = selected("Formant")

        # Extract features by chunk
        for counter from 1 to 'chunks'
          quotient = dur / chunks
          ch_start = quotient * (counter - 1) + jitter
          ch_end = ch_start + quotient

          select 'extractedObj'
          Extract part... ch_start ch_end Hanning 1 no
          Rename... 'name$'_chunked
          chunkedObj = selected("Sound")

          select 'formant_afterTracking'
          f1 = Get mean... 1 ch_start ch_end Hertz
          f2 = Get mean... 2 ch_start ch_end Hertz

          if min_formants > 3
            f3 = Get mean... 3 ch_start ch_end Hertz
            f4 = Get mean... 4 ch_start ch_end Hertz
          elsif min_formants > 2
            f3 = Get mean... 3 ch_start ch_end Hertz
            f4 = 0
          else
            f3 = 0
            f4 = 0
          endif

          # Get pitch
          select 'pitch_interpolated'
          pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

          if pitch_val = undefined
            pitch_val = 0
          endif

          # Get H1-H2
          select 'chunkedObj'
          To Spectrum (fft)
          spectrumObj = selected("Spectrum")

          To Ltas (1-to-1)
          ltasObj = selected("Ltas")

          if pitch_val <> undefined
            p10_nf0md = 'pitch_val' / 10
            lowerbh1 = 'pitch_val' - 'p10_nf0md'
            upperbh1 = 'pitch_val' + 'p10_nf0md'
            lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
            upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)
            h1db = Get maximum... 'lowerbh1' 'upperbh1' None
            #h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
            h2db = Get maximum... 'lowerbh2' 'upperbh2' None
            #h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None

            # Calculate potential voice quality correlates
            h1_minus_h2 = 'h1db' - 'h2db'
          else
            h1_minus_h2 = 0
          endif

          resultLine$ = "'resultLine$''h1_minus_h2',"

          select 'ltasObj'
          plus 'spectrumObj'
          plus 'chunkedObj'
          Remove
        endfor

        select 'formant_afterTracking'
        plus 'formant_beforeTracking'
        plus 'extractedObj'
        Remove
      endif
    endif


    # Extract features: [H1 - A1, H1 - A2, H1 - A3]
    if feature["h1_minus_a123"] = 1
      select 'soundObj'
      Extract part... start end "rectangular" 1 "no"
      extractedObj = selected("Sound")

      select 'extractedObj'
      To Formant (burg)... 0 number_formants maximum_formant window_length 50
      Rename... 'name$'_beforeTracking
      formant_beforeTracking = selected("Formant")

      no_formants = 0
      min_formants = Get minimum number of formants
      if min_formants > 3
        Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      elsif min_formants > 2
        Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      elsif min_formants > 1
        Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
      else
        no_formants = 1
      endif

      if no_formants = 1
        h1_minus_a1 = 0
        h1_minus_a2 = 0
        h1_minus_a3 = 0

        for counter from 1 to 'chunks'
          resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"
        endfor

        select 'formant_beforeTracking'
        plus 'extractedObj'
        Remove

      else
        Rename... 'name$'_afterTracking
        formant_afterTracking = selected("Formant")

        # Extract features by chunk
        for counter from 1 to 'chunks'
          quotient = dur / chunks
          ch_start = quotient * (counter - 1)
          ch_end = ch_start + quotient

          select 'extractedObj'
          Extract part...  ch_start ch_end Hanning 1 no
          Rename... 'name$'_chunked
          chunkedObj = selected("Sound")

          select 'formant_afterTracking'
          f1 = Get mean... 1 ch_start ch_end Hertz
          f2 = Get mean... 2 ch_start ch_end Hertz

          if min_formants > 3
            f3 = Get mean... 3 ch_start ch_end Hertz
            f4 = Get mean... 4 ch_start ch_end Hertz
          elsif min_formants > 2
            f3 = Get mean... 3 ch_start ch_end Hertz
            f4 = 0
          else
            f3 = 0
            f4 = 0
          endif

          # Get F0
          select 'pitch_interpolated'
          pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

          if pitch_val = undefined
            pitch_val = 0
          endif

          # Get h1_minus_h2
          select 'chunkedObj'
          To Spectrum (fft)
          spectrumObj = selected("Spectrum")
          To Ltas (1-to-1)
          ltasObj = selected("Ltas")

          if pitch_val <> undefined
            p10_nf0md = 'pitch_val' / 10
            lowerbh1 = 'pitch_val' - 'p10_nf0md'
            upperbh1 = 'pitch_val' + 'p10_nf0md'
            lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
            upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)
            select 'ltasObj'
            h1db = Get maximum... 'lowerbh1' 'upperbh1' None
            h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
            h2db = Get maximum... 'lowerbh2' 'upperbh2' None
            h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None
            rh1hz = round('h1hz')
            rh2hz = round('h2hz')

            # Get the a1, a2, a3 measurements.
            p10_f1hzpt = 'f1' / 10
            p10_f2hzpt = 'f2' / 10
            p10_f3hzpt = 'f3' / 10
            lowerba1 = 'f1' - 'p10_f1hzpt'
            upperba1 = 'f1' + 'p10_f1hzpt'
            lowerba2 = 'f2' - 'p10_f2hzpt'
            upperba2 = 'f2' + 'p10_f2hzpt'
            lowerba3 = 'f3' - 'p10_f3hzpt'
            upperba3 = 'f3' + 'p10_f3hzpt'
            a1db = Get maximum... 'lowerba1' 'upperba1' None
            a1hz = Get frequency of maximum... 'lowerba1' 'upperba1' None
            a2db = Get maximum... 'lowerba2' 'upperba2' None
            a2hz = Get frequency of maximum... 'lowerba2' 'upperba2' None
            a3db = Get maximum... 'lowerba3' 'upperba3' None
            a3hz = Get frequency of maximum... 'lowerba3' 'upperba3' None

            # Calculate potential voice quality correlates.
            h1_minus_a1 = 'h1db' - 'a1db'
            h1_minus_a2 = 'h1db' - 'a2db'
            h1_minus_a3 = 'h1db' - 'a3db'
          else
            h1_minus_a1 = 0
            h1_minus_a2 = 0
            h1_minus_a3 = 0
          endif

          resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"

          select 'ltasObj'
          plus 'spectrumObj'
          plus 'chunkedObj'
          Remove
        endfor

        select 'formant_afterTracking'
        plus 'formant_beforeTracking'
        plus 'extractedObj'
        Remove
      endif
    endif


    # Extract features: [sd, skewness, kurtosis, COG]
    if feature["sd_skewness_kurtosis_COG"] = 1
      select 'soundObj'

      Extract part... start end "rectangular" 1 "no"
      extractedObj = selected("Sound")

      # Extract features by chunk
      for counter from 1 to 'chunks'
        quotient = dur / chunks
        ch_start = quotient * (counter - 1)
        ch_end = ch_start + quotient

        select 'extractedObj'
        Extract part...  ch_start ch_end Hanning 1 no
        Rename... 'name$'_chunked
        chunkedObj = selected("Sound")

        To Spectrum (fft)
        spectrumObj = selected("Spectrum")

        grav = Get centre of gravity... 2
        sdev = Get standard deviation... 2
        skew = Get skewness... 2
        kurt = Get kurtosis... 2

        resultLine$ = "'resultLine$''sdev','skew','kurt','grav',"

        select 'spectrumObj'
        plus 'chunkedObj'
        Remove
      endfor

      select 'extractedObj'
      Remove
    endif

    # Delete the trailing comma in resultLine and write to the result file
    len = length(resultLine$)
    resultLine$ = mid$(resultLine$, 1, len-1)
    fileappend 'resultFile$' 'resultLine$''newline$'

    # Increment file_count
    file_count = file_count + 1

    date$ = date$()
    printline 'file_count'  file(s) processed: 'soundFile$' - 'date$'

    select all
    minus Strings sound_list
    Remove
  endfor

  # Clear all object
  select all
  Remove


################################################################################
## Extraction for all phonemes
################################################################################


elsif target = 1

  for iFile from 1 to numFiles
    # Read in a sound file
    select Strings sound_list
    soundFile$ = Get string... iFile
    # nowarn Read from file... 'directory$''soundFile$'
    Read from file... 'directory$''soundFile$'

  # Get filename without extension
    dot_idx = rindex(soundFile$, ".")
    name$ = left$(soundFile$, (dot_idx - 1))

    # Resample sound file if needed
    if (feature["duration"] = 1) and
      ... (feature["formants"] = 0) and
      ... (feature["pitch"] = 0) and
      ... (feature["intensity"] = 0) and
      ... (feature["h1_minus_h2"] = 0) and
      ... (feature["h1_minus_a123"] = 0) and
      ... (feature["sd_skewness_kurtosis_COG"] = 0)
      soundObj = selected("Sound")
    else
      Resample... 16000 50
      soundObj = selected("Sound")
    endif

    # Create pitch object
    if (feature["pitch"] = 1) or
      ... (feature["h1_minus_h2"] = 1) or
      ... (feature["h1_minus_a123"] = 1)
      select 'soundObj'
      To Pitch... 0 50 600
      pitch_tracking = selected("Pitch")
      Interpolate
      Rename... 'name$'_interpolated
      pitch_interpolated = selected("Pitch")
    endif

    # Create intensity object
    if feature["intensity"] = 1
      select 'soundObj'
      To Intensity... minimum_pitch 0.0 yes
      intensity_tracking = selected("Intensity")
    endif

    # Read in a TextGrid file
    tgfile$ = "'directory$''name$'.TextGrid"
    if fileReadable(tgfile$)
      # nowarn Read from file... 'tgfile$'
      Read from file... 'tgfile$'
      textgrid = selected("TextGrid")
      numIntervals = Get number of intervals... tierNumber

      # Extract features from every phoneme
      for iLabel from 1 to numIntervals
        select 'textgrid'
        label$ = Get label of interval... 'tierNumber' 'iLabel'

        select 'textgrid'
        start = Get starting point... tierNumber iLabel
        end = Get end point... tierNumber iLabel
        dur = end - start

        # Get labels of preceding and following phonemes
        if iLabel = 1
          left$ = "Start"
          right_idx = iLabel + 1
          right$ = Get label of interval... tierNumber right_idx
        elsif iLabel = numIntervals
          right$ = "End"
          left_idx = iLabel - 1
          left$ = Get label of interval... tierNumber left_idx
        elsif iLabel <> 1 and iLabel <> numIntervals
          left_idx = iLabel - 1
          right_idx = iLabel + 1
          left$ = Get label of interval... tierNumber left_idx
          right$ = Get label of interval... tierNumber right_idx
        endif

        # Start building resultLine; will write once at the end of the loop
        resultLine$ = "'name$','left$','label$','right$',"


        # Extract features: [start, end, duration]
        if feature["duration"] = 1
          resultLine$ = "'resultLine$''start','end','dur',"
        endif


        # Extract features: [f1, f2, f3, f4]
        if feature["formants"] = 1

          # Do not track or extract formants for SIL's which is subject to errors
          if startsWith(label$, "SIL")
            f1 = 0
            f2 = 0
            f3 = 0
            f4 = 0

            for counter from 1 to 'chunks'
              resultLine$ = "'resultLine$''f1','f2','f3','f4',"
            endfor

          else
            select 'soundObj'
            # Add jitter for more accurate formant tracking
            Extract part... start-jitter end+jitter "rectangular" 1 "no"
            extractedObj = selected("Sound")

            select 'extractedObj'
            To Formant (burg)... 0 number_formants maximum_formant window_length 50
            Rename... 'name$'_beforeTracking
            formant_beforeTracking = selected("Formant")

            no_formants = 0
            min_formants = Get minimum number of formants
            if min_formants > 3
              Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 2
              Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 1
              Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            else
              no_formants = 1
            endif

            if no_formants = 1
              f1 = 0
              f2 = 0
              f3 = 0
              f4 = 0

              for counter from 1 to 'chunks'
                resultLine$ = "'resultLine$''f1','f2','f3','f4',"
              endfor

            else
              Rename... 'name$'_afterTracking
              formant_afterTracking = selected("Formant")

              # Extract features by chunk
              for counter from 1 to 'chunks'
                quotient = dur / chunks
                ch_start = quotient * (counter - 1) + jitter
                ch_end = ch_start + quotient

                select 'formant_afterTracking'
                f1 = Get mean... 1 ch_start ch_end Hertz
                f2 = Get mean... 2 ch_start ch_end Hertz

                if min_formants > 3
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = Get mean... 4 ch_start ch_end Hertz
                elsif min_formants > 2
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = 0
                else
                  f3 = 0
                  f4 = 0
                endif
                resultLine$ = "'resultLine$''f1','f2','f3','f4',"
              endfor
            endif

            select 'formant_afterTracking'
            plus 'formant_beforeTracking'
            plus 'extractedObj'
            Remove
          endif
        endif


        # Extract features: [pitch]
        if feature["pitch"] = 1
          # Extract features by chunk
          for counter from 1 to 'chunks'
            quotient = dur / chunks
            ch_start = quotient * (counter - 1) + jitter
            ch_end = ch_start + quotient

            select 'pitch_interpolated'
            pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

            if pitch_val = undefined
              pitch_val = 0
            endif

            resultLine$ = "'resultLine$''pitch_val',"
          endfor
        endif


        # Extract features: [intensity]
        if feature["intensity"] = 1
          for counter from 1 to 'chunks'
            quotient = dur / chunks
            ch_start = quotient * (counter - 1) + jitter
            ch_end = ch_start + quotient

            select 'intensity_tracking'
            int = Get mean... start+quotient*(counter-1) start+quotient*counter dB

            resultLine$ = "'resultLine$''int',"
          endfor
        endif


        # Extract features: [H1 - H2]
        if feature["h1_minus_h2"] = 1

          # Do not extract H1-H2 for SIL's which is subject to errors
          if startsWith(label$, "SIL")
            h1_minus_h2 = 0

            for counter from 1 to 'chunks'
              resultLine$ = "'resultLine$''h1_minus_h2',"
            endfor

          else
            select 'soundObj'
            # Add jitter for accurate formant tracking
            Extract part... start-jitter end+jitter "rectangular" 1 "no"
            extractedObj = selected("Sound")

            select 'extractedObj'
            To Formant (burg)... 0 number_formants maximum_formant window_length 50
            Rename... 'name$'_beforeTracking
            formant_beforeTracking = selected("Formant")

            no_formants = 0
            min_formants = Get minimum number of formants
            if min_formants > 3
              Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 2
              Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 1
              Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            else
              no_formants = 1
            endif

            if no_formants = 1
              h1_minus_h2 = 0

              for counter from 1 to 'chunks'
                resultLine$ = "'resultLine$''h1_minus_h2',"
              endfor

              select 'formant_beforeTracking'
              plus 'extractedObj'
              Remove

            else
              Rename... 'name$'_afterTracking
              formant_afterTracking = selected("Formant")

              # Extract features by chunk
              for counter from 1 to 'chunks'
                quotient = dur / chunks
                ch_start = quotient * (counter - 1) + jitter
                ch_end = ch_start + quotient

                select 'extractedObj'
                Extract part... ch_start ch_end Hanning 1 no
                Rename... 'name$'_chunked
                chunkedObj = selected("Sound")

                select 'formant_afterTracking'
                f1 = Get mean... 1 ch_start ch_end Hertz
                f2 = Get mean... 2 ch_start ch_end Hertz

                if min_formants > 3
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = Get mean... 4 ch_start ch_end Hertz
                elsif min_formants > 2
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = 0
                else
                  f3 = 0
                  f4 = 0
                endif

                # Get pitch
                select 'pitch_interpolated'
                pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

                if pitch_val = undefined
                  pitch_val = 0
                endif

                # Get H1-H2
                select 'chunkedObj'
                To Spectrum (fft)
                spectrumObj = selected("Spectrum")

                To Ltas (1-to-1)
                ltasObj = selected("Ltas")

                if pitch_val <> undefined
                  p10_nf0md = 'pitch_val' / 10
                  lowerbh1 = 'pitch_val' - 'p10_nf0md'
                  upperbh1 = 'pitch_val' + 'p10_nf0md'
                  lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
                  upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)
                  h1db = Get maximum... 'lowerbh1' 'upperbh1' None
                  #h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
                  h2db = Get maximum... 'lowerbh2' 'upperbh2' None
                  #h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None

                  # Calculate potential voice quality correlates
                  h1_minus_h2 = 'h1db' - 'h2db'
                else
                  h1_minus_h2 = 0
                endif

                resultLine$ = "'resultLine$''h1_minus_h2',"

                select 'ltasObj'
                plus 'spectrumObj'
                plus 'chunkedObj'
                Remove
              endfor

              select 'formant_afterTracking'
              plus 'formant_beforeTracking'
              plus 'extractedObj'
              Remove
            endif
          endif
        endif


        # Extract features: [H1 - A1, H1 - A2, H1 - A3]
        if feature["h1_minus_a123"] = 1

          # Do not extract H1-A1/A2/A3 for SIL's which is subject to errors
          if startsWith(Label$, "SIL")
            h1_minus_a1 = 0
            h1_minus_a2 = 0
            h1_minus_a3 = 0

            for counter from 1 to 'chunks'
              resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"
            endfor

          else
            select 'soundObj'
            # Add jitter for accurate formant tracking
            Extract part... start-jitter end+jitter "rectangular" 1 "no"
            extractedObj = selected("Sound")

            To Formant (burg)... 0 number_formants maximum_formant window_length 50
            Rename... 'name$'_beforeTracking
            formant_beforeTracking = selected("Formant")

            no_formants = 0
            min_formants = Get minimum number of formants
            if min_formants > 3
              Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 2
              Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            elsif min_formants > 1
              Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
            else
              no_formants = 1
            endif

            if no_formants = 1
              h1_minus_a1 = 0
              h1_minus_a2 = 0
              h1_minus_a3 = 0

              for counter from 1 to 'chunks'
                resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"
              endfor

              select 'formant_beforeTracking'
              plus 'extractedObj'
              Remove

            else
              Rename... 'name$'_afterTracking
              formant_afterTracking = selected("Formant")

              # Extract features by chunk
              for counter from 1 to 'chunks'
                quotient = dur / chunks
                ch_start = quotient * (counter - 1) + jitter
                ch_end = ch_start + quotient

                select 'extractedObj'
                Extract part... ch_start ch_end Hanning 1 no
                Rename... 'name$'_chunked
                chunkedObj = selected("Sound")

                select 'formant_afterTracking'
                f1 = Get mean... 1 ch_start ch_end Hertz
                f2 = Get mean... 2 ch_start ch_end Hertz

                if min_formants > 3
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = Get mean... 4 ch_start ch_end Hertz
                elsif min_formants > 2
                  f3 = Get mean... 3 ch_start ch_end Hertz
                  f4 = 0
                else
                  f3 = 0
                  f4 = 0
                endif

                # Get pitch
                select 'pitch_interpolated'
                pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

                if pitch_val = undefined
                  pitch_val = 0
                endif

                # Get h1_minus_h2
                select 'chunkedObj'
                To Spectrum (fft)
                spectrumObj = selected("Spectrum")

                To Ltas (1-to-1)
                ltasObj = selected("Ltas")

                if pitch_val <> undefined
                  p10_nf0md = 'pitch_val' / 10
                  lowerbh1 = 'pitch_val' - 'p10_nf0md'
                  upperbh1 = 'pitch_val' + 'p10_nf0md'
                  lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
                  upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)
                  #select 'ltas'
                  h1db = Get maximum... 'lowerbh1' 'upperbh1' None
                  h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
                  h2db = Get maximum... 'lowerbh2' 'upperbh2' None
                  h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None
                  rh1hz = round('h1hz')
                  rh2hz = round('h2hz')

                  # Get A1, A2, A3 measurements
                  p10_f1hzpt = 'f1' / 10
                  p10_f2hzpt = 'f2' / 10
                  p10_f3hzpt = 'f3' / 10
                  lowerba1 = 'f1' - 'p10_f1hzpt'
                  upperba1 = 'f1' + 'p10_f1hzpt'
                  lowerba2 = 'f2' - 'p10_f2hzpt'
                  upperba2 = 'f2' + 'p10_f2hzpt'
                  lowerba3 = 'f3' - 'p10_f3hzpt'
                  upperba3 = 'f3' + 'p10_f3hzpt'
                  a1db = Get maximum... 'lowerba1' 'upperba1' None
                  a1hz = Get frequency of maximum... 'lowerba1' 'upperba1' None
                  a2db = Get maximum... 'lowerba2' 'upperba2' None
                    a2hz = Get frequency of maximum... 'lowerba2' 'upperba2' None
                  a3db = Get maximum... 'lowerba3' 'upperba3' None
                  a3hz = Get frequency of maximum... 'lowerba3' 'upperba3' None

                  # Calculate potential voice quality correlates.
                  h1_minus_a1 = 'h1db' - 'a1db'
                  h1_minus_a2 = 'h1db' - 'a2db'
                  h1_minus_a3 = 'h1db' - 'a3db'
                else
                  h1_minus_a1 = 0
                  h1_minus_a2 = 0
                  h1_minus_a3 = 0
                endif

                resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"

                select 'ltasObj'
                plus 'spectrumObj'
                plus 'chunkedObj'
                Remove
              endfor

              select 'formant_afterTracking'
              plus 'formant_beforeTracking'
              plus 'extractedObj'
              Remove
            endif
          endif
        endif

        # Extract features: [sd, skewness, kurtosis, COG]
        if feature["sd_skewness_kurtosis_COG"] = 1

          # Do not track or extract formants for SIL's which is subject to errors
          if startsWith(label$, "SIL")
            grav = 0
            sdev = 0
            skew = 0
            kurt = 0

            for counter from 1 to 'chunks'
              resultLine$ = "'resultLine$''sdev','skew','kurt','grav',"
            endfor

          else
            select 'soundObj'
            # Add jitter for accurate formant tracking
            Extract part... start-jitter end+jitter "rectangular" 1 "no"
            extractedObj = selected("Sound")

            # Extract features by chunk
            for counter from 1 to 'chunks'
              quotient = dur / chunks
              ch_start = quotient * (counter - 1) + jitter
              ch_end = ch_start + quotient

              select 'extractedObj'
              Extract part...  ch_start ch_end Hanning 1 no
              Rename... 'name$'_chunked
              chunkedObj = selected("Sound")

              To Spectrum (fft)
              spectrumObj = selected("Spectrum")

              grav = Get centre of gravity... 2
              sdev = Get standard deviation... 2
              skew = Get skewness... 2
              kurt = Get kurtosis... 2

              resultLine$ = "'resultLine$''sdev','skew','kurt','grav',"

              select 'spectrumObj'
              plus 'chunkedObj'
              Remove
            endfor

            select 'extractedObj'
            Remove
          endif
        endif


        # Delete the trailing comma in resultLine and write to the result file
        len = length(resultLine$)
        resultLine$ = mid$(resultLine$, 1, len-1)
        fileappend "'resultFile$'" 'resultLine$''newline$'

      endfor

    endif

    file_count = file_count + 1

    date$ = date$()
    printline 'file_count'  file(s) processed: 'soundFile$' - 'date$'

    # Clear object window
    select all
    minus Strings sound_list
    minus Strings textgrid_list
    Remove
  endfor

  select all
  Remove


################################################################################
## Extraction for phones in phoneme set only
################################################################################


elsif target = 2

  # Exit if phoneme set is not specified
  if length(phoneme_set$) = 0
    exitScript: "Phonemes are not specified."
  endif

  # Get phonemes in phoneme set and assign to array
  count = 1
  comma_idx = index(phoneme_set$, ",")

  while comma_idx <> 0
    one$ = left$(phoneme_set$, (comma_idx - 1))
    length = length(phoneme_set$)
    phoneme_set$ = right$(phoneme_set$, (length - comma_idx))
    comma_idx = index(phoneme_set$, ",")
    phonemes$[count] = one$
    count = count + 1
  endwhile

  # assign last one to array
  one$ = phoneme_set$
  phonemes$[count] = one$

  for iFile from 1 to numFiles
    # Read in a sound file
    select Strings sound_list
    soundFile$ = Get string... iFile
    #nowarn Read from file... 'directory$''soundFile$'
    Read from file... 'directory$''soundFile$'

    # Get filename without extension
    dot_idx = rindex(soundFile$, ".")
    name$ = left$(soundFile$, (dot_idx - 1))

    # Resample sound file if needed
    if (feature["duration"] = 1) and
      ... (feature["formants"] = 0) and
      ... (feature["pitch"] = 0) and
      ... (feature["intensity"] = 0) and
      ... (feature["h1_minus_h2"] = 0) and
      ... (feature["h1_minus_a123"] = 0) and
      ... (feature["sd_skewness_kurtosis_COG"] = 0)
      soundObj = selected("Sound")
    else
      Resample... 16000 50
      soundObj = selected("Sound")
    endif

    # Create pitch object
    if (feature["pitch"] = 1) or
      ... (feature["h1_minus_h2"] = 1) or
      ... (feature["h1_minus_a123"] = 1)
      select 'soundObj'
      To Pitch... 0 50 600
      pitch_tracking = selected("Pitch")
      Interpolate
      Rename... 'name$'_interpolated
      pitch_interpolated = selected("Pitch")
    endif

    # Create intensity object
    if feature["intensity"] = 1
      select 'soundObj'
      To Intensity... minimum_pitch 0.0 yes
      intensity_tracking = selected("Intensity")
    endif

    # Read in a TextGrid file
    tgfile$ = "'directory$''name$'.TextGrid"
    if fileReadable(tgfile$)
      # nowarn Read from file... 'tgfile$'
      Read from file... 'tgfile$'
      textgrid = selected("TextGrid")
      numIntervals = Get number of intervals... tierNumber

      # Extract features from phonemes in phoneme set
      for iLabel from 1 to numIntervals
        select 'textgrid'
        label$ = Get label of interval... 'tierNumber' 'iLabel'

        for idx from 1 to count

          # if label$ is in phoneme set, extract
          if phonemes$[idx] = label$
            select 'textgrid'
            start = Get starting point... tierNumber iLabel
            end = Get end point... tierNumber iLabel
            dur = end - start

            # Get labels of preceding and following phonemes
            if iLabel = 1
              left$ = "Start"
              right_idx = iLabel + 1
              right$ = Get label of interval... tierNumber right_idx
            elsif iLabel = numIntervals
              right$ = "End"
              left_idx = iLabel - 1
              left$ = Get label of interval... tierNumber left_idx
            elsif iLabel <> 1 and iLabel <> numIntervals
              left_idx = iLabel - 1
              right_idx = iLabel + 1
              left$ = Get label of interval... tierNumber left_idx
              right$ = Get label of interval... tierNumber right_idx
            endif

            # Start building resultLine; will write once at the end of the loop
            resultLine$ = "'name$','left$','label$','right$',"


            # Extract features: [start, end, duration]
            if feature["duration"] = 1
              resultLine$ = "'resultLine$''start','end','dur',"
            endif


            # Extract features: [f1, f2, f3, f4]
            if feature["formants"] = 1
              select 'soundObj'
              # Add jitter for accurate formant tracking
              Extract part... start-jitter end+jitter "rectangular" 1 "no"
              extractedObj = selected("Sound")

              To Formant (burg)... 0 number_formants maximum_formant window_length 50
              Rename... 'name$'_beforeTracking
              formant_beforeTracking = selected("Formant")

              no_formants = 0
              min_formants = Get minimum number of formants
              if min_formants > 3
                Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 2
                Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 1
                Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              else
                no_formants = 1
              endif

              if no_formants = 1
                h1_minus_h2 = 0

                for counter from 1 to 'chunks'
                  resultLine$ = "'resultLine$''f1','f2','f3','f4',"
                endfor

                select 'formant_beforeTracking'
                plus 'extractedObj'
                Remove

              else
                Rename... 'name$'_afterTracking
                formant_afterTracking = selected("Formant")

                # Extract features by chunk
                for counter from 1 to 'chunks'
                  quotient = dur / chunks
                  ch_start = quotient * (counter - 1) + jitter
                  ch_end = ch_start + quotient

                  select 'formant_afterTracking'
                  f1 = Get mean... 1 ch_start ch_end Hertz
                  f2 = Get mean... 2 ch_start ch_end Hertz

                  if min_formants > 3
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = Get mean... 4 ch_start ch_end Hertz
                  elsif min_formants > 2
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = 0
                  else
                    f3 = 0
                    f4 = 0
                  endif

                  resultLine$ = "'resultLine$''f1','f2','f3','f4',"
                endfor
              endif

              select 'formant_afterTracking'
              plus 'formant_beforeTracking'
              plus 'extractedObj'
              Remove
            endif


            # Extract features: [pitch]
            if feature["pitch"] = 1
              # Extract features by chunk
              for counter from 1 to 'chunks'
                quotient = dur / chunks
                ch_start = quotient * (counter - 1) + jitter
                ch_end = ch_start + quotient

                select 'pitch_interpolated'
                pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

                if pitch_val = undefined
                  pitch_val = 0
                endif

                resultLine$ = "'resultLine$''pitch_val',"
              endfor
            endif


            # Extract features: [intensity]
            if feature["intensity"] = 1
              # Extract features by chunk
              for counter from 1 to 'chunks'
                quotient = dur / chunks
                ch_start = quotient * (counter - 1) + jitter
                ch_end = ch_start + quotient

                select 'intensity_tracking'
                int = Get mean... start+quotient*(counter-1) start+quotient*counter dB

                resultLine$ = "'resultLine$''int',"
              endfor
            endif


            # Extract features: [H1 - H2]
            if feature["h1_minus_h2"] = 1
              select 'soundObj'
              # Add jitter for accurate formant tracking
              Extract part... start-jitter end+jitter "rectangular" 1 "no"
              extractedObj = selected("Sound")

              To Formant (burg)... 0 number_formants maximum_formant window_length 50
              Rename... 'name$'_beforeTracking
              formant_beforeTracking = selected("Formant")

              no_formants = 0
              min_formants = Get minimum number of formants
              if min_formants > 3
                Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 2
                Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 1
                Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              else
                no_formants = 1
              endif

              if no_formants = 1
                h1_minus_h2 = 0

                for counter from 1 to 'chunks'
                  resultLine$ = "'resultLine$''h1_minus_h2',"
                endfor

                select 'formant_beforeTracking'
                plus 'extractedObj'
                Remove

              else
                Rename... 'name$'_afterTracking
                formant_afterTracking = selected("Formant")

                # Extract features by chunk
                for counter from 1 to 'chunks'
                  quotient = dur / chunks
                  ch_start = quotient * (counter - 1) + jitter
                  ch_end = ch_start + quotient

                  select 'extractedObj'
                  Extract part...  ch_start ch_end Hanning 1 no
                  Rename... 'name$'_chunked
                  chunkedObj = selected("Sound")

                  select 'formant_afterTracking'
                  f1 = Get mean... 1 ch_start ch_end Hertz
                  f2 = Get mean... 2 ch_start ch_end Hertz

                  if min_formants > 3
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = Get mean... 4 ch_start ch_end Hertz
                  elsif min_formants > 2
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = 0
                  else
                    f3 = 0
                    f4 = 0
                  endif

                  # Get pitch
                  select 'pitch_interpolated'
                  pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

                  if pitch_val = undefined
                    pitch_val = 0
                  endif

                  # Get h1_minus_h2
                  select 'chunkedObj'
                  To Spectrum (fft)
                  spectrumObj = selected("Spectrum")

                  To Ltas (1-to-1)
                  ltasObj = selected("Ltas")

                  if pitch_val <> undefined
                    p10_nf0md = 'pitch_val' / 10
                    lowerbh1 = 'pitch_val' - 'p10_nf0md'
                    upperbh1 = 'pitch_val' + 'p10_nf0md'
                    lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
                    upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)
                    h1db = Get maximum... 'lowerbh1' 'upperbh1' None
                    #h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
                    h2db = Get maximum... 'lowerbh2' 'upperbh2' None
                    #h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None

                    # Calculate potential voice quality correlates.
                    h1_minus_h2 = 'h1db' - 'h2db'
                  else
                    h1_minus_h2 = 0
                  endif

                  resultLine$ = "'resultLine$''h1_minus_h2',"

                  select 'ltasObj'
                  plus 'spectrumObj'
                  plus 'chunkedObj'
                  Remove
                endfor

                select 'formant_afterTracking'
                plus 'formant_beforeTracking'
                plus 'extractedObj'
                Remove
              endif
            endif


            # Extract features: [H1 - A1, H1 - A2, H1 - A3]
            if feature["h1_minus_a123"] = 1
              select 'soundObj'
              # Add jitter for accurate formant tracking
              Extract part... start-jitter end+jitter "rectangular" 1 "no"
              extractedObj = selected("Sound")

              To Formant (burg)... 0 number_formants maximum_formant window_length 50
              Rename... 'name$'_beforeTracking
              formant_beforeTracking = selected("Formant")

              no_formants = 0
              min_formants = Get minimum number of formants
              if min_formants > 3
                Track... 4 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 2
                Track... 3 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              elsif min_formants > 1
                Track... 2 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 'freqcost' 'bwcost' 'transcost'
              else
                no_formants = 1
              endif

              if no_formants = 1
                h1_minus_a1 = 0
                h1_minus_a2 = 0
                h1_minus_a3 = 0

                for counter from 1 to 'chunks'
                  resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"
                endfor

                select 'formant_beforeTracking'
                plus 'extractedObj'
                remove

              else
                Rename... 'name$'_afterTracking
                formant_afterTracking = selected("Formant")

                # Extract features by chunk
                for counter from 1 to 'chunks'
                  quotient = dur / chunks
                  ch_start = quotient * (counter - 1) + jitter
                  ch_end = ch_start + quotient

                  select 'extractedObj'
                  Extract part...  ch_start ch_end Hanning 1 no
                  Rename... 'name$'_chunked
                  chunkedObj = selected("Sound")

                  select 'formant_afterTracking'
                  f1 = Get mean... 1 ch_start ch_end Hertz
                  f2 = Get mean... 2 ch_start ch_end Hertz

                  if min_formants > 3
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = Get mean... 4 ch_start ch_end Hertz
                  elsif min_formants > 2
                    f3 = Get mean... 3 ch_start ch_end Hertz
                    f4 = 0
                  else
                    f3 = 0
                    f4 = 0
                  endif

                  # Get pitch
                  select 'pitch_interpolated'
                  pitch_val = Get mean... start+quotient*(counter-1) start+quotient*counter Hertz

                  if pitch_val = undefined
                    pitch_val = 0
                  endif

                  # Get h1_minus_h2
                  select 'chunkedObj'
                  To Spectrum (fft)
                  spectrumObj = selected("Spectrum")

                  To Ltas (1-to-1)
                  ltasObj = selected("Ltas")

                  if pitch_val <> undefined
                    p10_nf0md = 'pitch_val' / 10
                    lowerbh1 = 'pitch_val' - 'p10_nf0md'
                    upperbh1 = 'pitch_val' + 'p10_nf0md'
                    lowerbh2 = ('pitch_val' * 2) - ('p10_nf0md' * 2)
                    upperbh2 = ('pitch_val' * 2) + ('p10_nf0md' * 2)

                    h1db = Get maximum... 'lowerbh1' 'upperbh1' None
                    h1hz = Get frequency of maximum... 'lowerbh1' 'upperbh1' None
                    h2db = Get maximum... 'lowerbh2' 'upperbh2' None
                    h2hz = Get frequency of maximum... 'lowerbh2' 'upperbh2' None
                    rh1hz = round('h1hz')
                    rh2hz = round('h2hz')

                    # Get the A1, A2, A3 measurements.
                    p10_f1hzpt = 'f1' / 10
                    p10_f2hzpt = 'f2' / 10
                    p10_f3hzpt = 'f3' / 10
                    lowerba1 = 'f1' - 'p10_f1hzpt'
                    upperba1 = 'f1' + 'p10_f1hzpt'
                    lowerba2 = 'f2' - 'p10_f2hzpt'
                    upperba2 = 'f2' + 'p10_f2hzpt'
                    lowerba3 = 'f3' - 'p10_f3hzpt'
                    upperba3 = 'f3' + 'p10_f3hzpt'

                    a1db = Get maximum... 'lowerba1' 'upperba1' None
                    a1hz = Get frequency of maximum... 'lowerba1' 'upperba1' None
                    a2db = Get maximum... 'lowerba2' 'upperba2' None
                    a2hz = Get frequency of maximum... 'lowerba2' 'upperba2' None
                    a3db = Get maximum... 'lowerba3' 'upperba3' None
                    a3hz = Get frequency of maximum... 'lowerba3' 'upperba3' None

                    # Calculate potential voice quality correlates.
                    h1_minus_a1 = 'h1db' - 'a1db'
                    h1_minus_a2 = 'h1db' - 'a2db'
                    h1_minus_a3 = 'h1db' - 'a3db'
                  else
                    h1_minus_a1 = 0
                    h1_minus_a2 = 0
                    h1_minus_a3 = 0
                  endif

                  resultLine$ = "'resultLine$''h1_minus_a1','h1_minus_a2','h1_minus_a3',"

                  select 'ltasObj'
                  plus 'spectrumObj'
                  plus 'chunkedObj'
                  Remove
                endfor

                select 'formant_afterTracking'
                plus 'formant_beforeTracking'
                plus 'extractedObj'
                Remove
              endif
            endif


            # Extract features: [sd, skewness, kurtosis, COG]
            if feature["sd_skewness_kurtosis_COG"] = 1

              # Do not track or extract formants for SIL's which is subject to errors
              if startsWith(label$, "SIL")
                grav = 0
                sdev = 0
                skew = 0
                kurt = 0

                for counter from 1 to 'chunks'
                  resultLine$ = "'resultLine$''sdev','skew','kurt','grav',"
                endfor

              else
                select 'soundObj'
                # Add jitter for accurate formant tracking
                Extract part... start-jitter end+jitter "rectangular" 1 "no"
                extractedObj = selected("Sound")

                # Extract features by chunk
                for counter from 1 to 'chunks'
                  quotient = dur / chunks
                  ch_start = quotient * (counter - 1) + jitter
                  ch_end = ch_start + quotient

                  select 'extractedObj'
                  Extract part...  ch_start ch_end Hanning 1 no
                  Rename... 'name$'_chunked
                  chunkedObj = selected("Sound")

                  To Spectrum (fft)
                  spectrumObj = selected("Spectrum")

                  grav = Get centre of gravity... 2
                  sdev = Get standard deviation... 2
                  skew = Get skewness... 2
                  kurt = Get kurtosis... 2

                  resultLine$ = "'resultLine$''sdev','skew','kurt','grav',"

                  select 'spectrumObj'
                  plus 'chunkedObj'
                  Remove
                endfor

                select 'extractedObj'
                Remove
              endif
            endif

            # Delete the trailing comma in resultLine and write to the result file
            len = length(resultLine$)
            resultLine$ = mid$(resultLine$, 1, len-1)
            fileappend 'resultFile$' 'resultLine$''newline$'

          endif

        endfor
      endfor
    endif

    file_count = file_count + 1

    date$ = date$()
    printline 'file_count'  file(s) processed: 'soundFile$' - 'date$'

    # Clear object window
    select all
    minus Strings sound_list
    minus Strings textgrid_list
    Remove
  endfor

  select all
  Remove
endif


# print statistics
enddate$ = date$()

printline 'delim$'
printline 'newline$'All completed !'newline$'

printline Started on 'startdate$'
printline Ended on 'enddate$'
