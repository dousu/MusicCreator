
\version "2.16.2"
% automatically converted by musicxml2ly from msc-10.xml

\header {
    encodingsoftware = "Finale for Windows"
    encodingdate = "2012-10-10"
    }

\layout {
    \context { \Score
        autoBeaming = ##f
        }
    }
PartPOneVoiceOne =  \relative g' {
    \clef "treble" \key es \major \time 1/4 g8 ( [ g8 ] | % 2
    \time 3/4  bes4. g8 g4 | % 3
    bes2 ) g8 ( [ bes8 ] | % 4
    es4 d4. c8 | % 5
    c4 bes4 ) f8 ( [ g8 ] \break | % 6
    as4 f4 f8 [ g8 ] | % 7
    as2 ) f8 ( [ as8 ] | % 8
    d8 [ c8 ] bes4 d4 | % 9
    \time 2/4  es2 ) \bar "|."
    }


% The score definition
\score {
    <<
        \new Staff <<
            \context Staff << 
                \context Voice = "PartPOneVoiceOne" { \PartPOneVoiceOne }
                >>
            >>
        
        >>
    \layout {}
    % To create MIDI output, uncomment the following line:
    %  \midi {}
    }

