LET $input = "824-1475,967620-1012917,2727216511-2727316897,56345-141494,8811120-8999774,5727326-5922513,935306-961989,76751455-76787170,723458-849157,144648-162230,1597-3207,326085-472746,14-34,66-132,9453977670-9454023729,959903262-960027272,17168-26699,190-332,3351-5602,1-11,371280315-371448887,6252062-6312899,9696887156-9697040132,37-58,32770-52161,6443650762-6443689882,473092-582157,3309726-3347079,852735-912990,8294840594-8294926063,3773964-3884030,7718304-7809359,601947-677833,3434304207-3434405118,449-673,64525269-64702774,31545468-31784543,184451-308951,5771-11485";

-- Extract ranges from text input
LET $patternDefs = $input.split(',')
    -- extract "from" and "to"
    .map(|$range| {
        LET $splitRange = $range.split('-');
        LET $result = {
            from: $splitRange[0],
            to: $splitRange[1]
        };
        $result;
    })
    -- Prep list of ranges to generate repetitions to test
    .map(|$range| {
        LET $isDiffLength = $range.from.len() != $range.to.len();
        LET $maxPatternDigits = ($range.to.len() / 2);
        LET $patternLengths = <array> 1..($maxPatternDigits + 1);
        LET $rangeData = {
            from: $range.from,
            to: $range.to,
            isDiffLength: $isDiffLength,
            maxPatternDigits: $maxPatternDigits
        };

        LET $initState = {data: $rangeData, perms: []};
        LET $patternDefs = $patternLengths.fold($initState, |$state, $patternLen| {
            
            // Each pattern definition may have multiple ranges to generate the pattern for
            LET $rangesToGenerate = IF $state.data.isDiffLength {
                -- Handle different lenghts
                LET $repsLeft = $state.data.from.len() / $patternLen;
                LET $isDivisibleLeft = IF ($state.data.from.len() = $repsLeft * $patternLen) { true; } ELSE { false; };
                LET $resultLeft = IF $repsLeft > 1 AND $isDivisibleLeft {
                    LET $newRange = {
                        from: $state.data.from.slice(0,$patternLen),
                        to: array::repeat('9', $patternLen).join(''),
                        patternLen: $patternLen,
                        reps: $repsLeft,
                    };
                    $newRange;
                } ELSE {
                    LET $noRange = NONE;
                    $noRange;
                };
            
                LET $repsRight = $state.data.from.len() / $patternLen;
                LET $isDivisibleRight = IF ($state.data.to.len() = $repsRight * $patternLen) { true; } ELSE { false; };
                LET $resultRight = IF $repsRight > 1 AND $isDivisibleRight {
                    LET $newRange = {
                        from: '1' + array::repeat('0', $patternLen - 1).join(''),
                        to: $state.data.to.slice(0,$patternLen),
                        patternLen: $patternLen,
                        reps: $repsRight,
                    };
                    $newRange;
                } ELSE {
                    LET $noRange = NONE;
                    $noRange;
                };
                
                LET $result = [$resultLeft, $resultRight];
                $result;
            } ELSE {
                -- Handle same length, ie. 1234-4321
                LET $reps = $state.data.from.len() / $patternLen;
                LET $isDivisible = IF ($state.data.from.len() = $reps * $patternLen) { true; } ELSE { false; }; -- No modulo operator :(
            
                LET $result = IF $reps > 1 AND $isDivisible {
                    LET $newRange = [{
                        from: $state.data.from.slice(0,$patternLen),
                        to: $state.data.to.slice(0,$patternLen),
                        patternLen: $patternLen,
                        reps: $reps,
                    }];
                    $newRange;
                } ELSE {
                    LET $noRange = [];
                    $noRange;
                };
                $result;
            };





            
            LET $newPerm = {
                from: $state.data.from,
                to: $state.data.to,
                isDiffLength: $state.data.isDiffLength,
                maxPatternDigits: $state.data.maxPatternDigits,
                patternLength: $patternLen,
                rangesToGenerate: $rangesToGenerate,
            };
            LET $result = {
                data: $state.data,
                perms: $state.perms.append($newPerm)
            };
            $result;
        });
        $patternDefs
    })
    .map(|$foldedRange| $foldedRange.perms)
    .flatten();

-- RETURN $patternDefs;
-- Array of pattern definitions:
-- {
--     from: '824',
--     isDiffLength: true,
--     maxPatternDigits: 2,
--     patternLength: 1,
--     rangesToGenerate: [
--         {
--             from: '8',
--             patternLen: 1,
--             reps: 3,
--             to: '9'
--         },
--         NONE
--     ],
--     to: '1475'
-- }

FOR $patternDef IN $patternDefs {
  FOR $patternDefEntry IN $patternDef.rangesToGenerate {
    IF $patternDefEntry != NONE {
      LET $range = (<int>$patternDefEntry.from)..=(<int>$patternDefEntry.to);
      FOR $subpatternInt IN $range {
        LET $potentialHit = <int>array::repeat(<string>$subpatternInt, $patternDefEntry.reps).join('');
        IF $potentialHit >= <int>$patternDef.from && $potentialHit <= <int>$patternDef.to {
          UPSERT type::thing("hit", $potentialHit) SET
            value = <decimal>$potentialHit,
            range = $range,
            patternDef = $patternDef,
            patternDefEntry = $patternDefEntry;
        };
      };
    };
  };
};

SELECT math::sum(value) FROM hit GROUP ALL;
