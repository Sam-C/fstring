classdef FStringTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % input types %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function charArrayInput(testCase)
            testCase.verifyEqual(f('ok'), 'ok');
        end

        function emptyCharInput(testCase)
            testCase.verifyEqual(f(''), char.empty(1,0)); % because f() will output 1xN characters
        end

        function stringScalarInput(testCase)
            testCase.verifyEqual(f("ok"), "ok");
        end

        function emptyStringInput(testCase)
            testCase.verifyEqual(f(""), "");
        end

        function missingStringInput(testCase)
            testCase.verifyError(@()f(string(missing)), 'MATLAB:expectedScalartext');
        end

        % literals and expressions mixing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function multipleExpressions(testCase)
            testCase.verifyEqual(f('{"o"+"k"}{50+50}'), 'ok100');
        end

        function ExpressionsBetweenLiterals(testCase)
            testCase.verifyEqual(f('<{"o"+"k"}_{50+50}>'), '<ok_100>');
        end

        function expressionAndLiteralFormFormattingOperator(testCase)
            testCase.verifyEqual(f('{"%"}d'), '%d');
        end

        function expressionAndLiteralFormSpecialCharacter(testCase)
            testCase.verifyEqual(f('{"\"}n'), '\n');
        end
        
        % curly braces behavior  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function escapeCurlyBracesInLiteral(testCase)
            testCase.verifyEqual(f('text{{text}}text'), 'text{text}text');
        end

        function unmatchedOpeningCurlyBrace(testCase)
            testCase.verifyError(@()f('{'), 'FString:unmatchedOpeningCurlyBrace');
        end

        function unmatchedClosingCurlyBrace(testCase)
            testCase.verifyError(@()f('}'), 'FString:unmatchedClosingCurlyBrace');
        end

        function curlyBracesInExpression(testCase)
            cellArray = {10,20};
            testCase.verifyEqual(f('{ cellArray{2} }'), '20');
        end

        function unmatchedCurlyBraceInStringInExpression(testCase)
            % don't treat curly brace in string as expression-opener/closer
            testCase.verifyEqual(f('{ "e}{e" }'), 'e}{e');
        end

        function DoubleCurlyBracesInStringInExpression(testCase)
            % don't escape double curly braces in string in expression
            testCase.verifyEqual(f("{ 'e{{e' }"), "e{{e");
        end

        function quotesInStringInExpression(testCase)
            testCase.verifyEqual(f("{ 'single quote<''>, double quote<"">' }"), "single quote<'>, "+'double quote<">');
        end

        function transposeInExpression(testCase)
            % these are transpose, not single-quoted string
            testCase.verifyEqual(f("{[1]'} {ones'}"), "1 1");
        end
 
        function unclosedSingleQuotedStringInExpression(testCase)
            testCase.verifyError(@()f("{'hi}"), 'FString:unclosedSingleQuotedStringInExpression');
        end

        function unclosedDoubleQuotedStringInExpression(testCase)
            testCase.verifyError(@()f('{"hi}'), 'FString:unclosedDoubleQuotedStringInExpression');
        end

        function wrongCurlyBracesInExpression(testCase)
            testCase.verifyError(@()f('0{1{2}1}0'), 'MATLAB:m_improper_grouping');
        end

        % literal: formatting  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newlineInText(testCase)
            testCase.verifyEqual(f('\n'), newline);
        end

        function percentInText(testCase)
            testCase.verifyEqual(f('%d'), '%d');
        end

        function percentpercentInText(testCase)
            testCase.verifyEqual(f('%%'), '%%');
        end

        % expression: types %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function numericalExpression(testCase)
            testCase.verifyEqual(f('{5+3}'), '8');
        end

        function stringExpression(testCase)
            testCase.verifyEqual(f('{"o"+"k"}'), 'ok');
        end

        function functionExpression(testCase)
            testCase.verifyEqual(f('{sqrt(4)}'), '2');
        end

        function variableExpression(testCase)
            var1 = "42";
            testCase.verifyEqual(f('{var1}'), '42');
        end

        function cellExpression(testCase)
            % cell scalar of chars will be converted to string with string(). Is that ok?
            testCase.verifyEqual(f("{ {'ok'} }"), "ok");
            testCase.verifyEqual(f("{ {{{'ok'}}} }"), "ok");
        end

        function arrayExpression(testCase)
            % this will fail because array cannot be converted to string scalar
            testCase.verifyError(@()f('{ [1,2,3] }'), 'MATLAB:string:MustBeConvertibleCellArray');
        end

        function cannotConvertThisToString(testCase)
            testCase.verifyError(@()f("{ {'ok', 'wow'} }"), 'MATLAB:string:MustBeConvertibleCellArray');
        end

        function nestedFStringExpression(testCase)
            chars = '<e></e>';
            testCase.verifyEqual(...
                f('<a>{ f("<b>{ f(''<c>{ f(""<d>{ f(''''{chars}'''') }</d>"") }</c>'') }</b>") }</a>'), ...
                '<a><b><c><d><e></e></d></c></b></a>');
        end

        % expression: displayed text %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function equalSignInExpression(testCase)
            testCase.verifyEqual(f('{5+3=}'), '5+3=8');
        end

        function equalSignAndSpacesInExpression(testCase)
            testCase.verifyEqual(f('{ 5 + 3 = }'),  ' 5 + 3 = 8');
        end

        function equalSignAndNonSpaceInExpression(testCase)
            testCase.verifyError(@()f('{ 5 + 3 = ?}'), 'FString:nonSpaceCharAfterEqual');
        end

        % expression: format Specifier %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function noFormatSpecifier(testCase)
            testCase.verifyEqual(f("{0.123456789}"), string(0.123456789));
        end

        function formatSpecifier(testCase)
            testCase.verifyEqual(f('{0.123456789:%0.3f}'), '0.123');
        end

        function tooManyFormatSpecifiers(testCase)
            testCase.verifyEqual(f('{0.123456789:%0.3f%f}'), '0.123%f');
        end

        function tooFewFormatSpecifier(testCase)
            testCase.verifyError(@()f('{0.123456789:_}'), 'MATLAB:string:NoHoles');
        end

        % expression: displayed text with format specifier %%%%%%%%%%%%%%%%

        function displayedTextWithFormatSpecifier(testCase)
            % variable, numbers, function, expression displayed text,
            % format specifier
            var1 = 1;
            testCase.verifyEqual(f('result: {plus(var1,22/7) = :%0.6f}'), ...
                'result: plus(var1,22/7) = 4.142857');
        end
    end

end
