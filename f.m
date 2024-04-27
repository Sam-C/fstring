function formattedString = f(input)
    validateattributes(input, {'char', 'string'}, {'scalartext'});
    inputChars = char(input);

    [literals, expressions] = extractLiteralsAndExpressions(inputChars);

    formattedLiterals = formatLiteral(literals);

    expressionStructs = parseExpression(expressions);

    for i = 1:numel(expressionStructs)
        expressionStructs(i).evaluatedValue = {evalin('caller', expressionStructs(i).expression)};
    end

    formattedExpressions = formatExpression(expressionStructs);

    formattedParts = interlace(formattedLiterals, formattedExpressions);

    formattedString = strjoin(formattedParts, '');

    if isstring(input)
        formattedString = string(formattedString);
    end
end

function [literals, expressions] = extractLiteralsAndExpressions(inputChars)
    arguments
        inputChars (1,:) char
    end

    IN_LITERAL = 1;
    IN_EXPRESSION = 2;
    IN_EXPRESSION_AND_SINGLE_QUOTED_STRING = 3;
    IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING = 4;

    literals = {};
    expressions = {};

    state = IN_LITERAL;
    buffer = '';
    braceDepth = 0;
    inputCharsLength = numel(inputChars);
    i = 1;

    while i <= inputCharsLength
        if i - 1 >= 1
            previousChar = inputChars(i-1);
        else
            previousChar = '';
        end
        currentChar = inputChars(i);
        if i + 1 <= inputCharsLength
            nextChar = inputChars(i+1);
        else
            nextChar = '';
        end

        switch state
            case IN_LITERAL
                switch currentChar
                    case '{'
                        if nextChar == '{'
                            buffer(end+1:end+2) = '{{';
                            i = i + 1;
                            state = IN_LITERAL;
                        else
                            literals{end+1} = buffer;
                            buffer = '';
                            braceDepth = braceDepth + 1;
                            state = IN_EXPRESSION;
                        end
                    case '}'
                        if nextChar == '}'
                            buffer(end+1:end+2) = '}}';
                            i = i + 1;
                            state = IN_LITERAL;
                        else
                            e = MException("FString:unmatchedClosingCurlyBrace", ...
                                "Closing curly brace '}' found without a corresponding opening curly brace '{'.");
                            throw(e);
                        end
                    otherwise
                        buffer(end+1) = currentChar;
                        state = IN_LITERAL;
                end
            case IN_EXPRESSION
                switch currentChar
                    case '{'
                        braceDepth = braceDepth + 1;
                        buffer(end+1) = currentChar;
                        state = IN_EXPRESSION;
                    case ''''
                        if ismember(previousChar, '.+-*/\^=~<>&|@,:;([{ ')
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION_AND_SINGLE_QUOTED_STRING;
                        else
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION;
                        end
                    case '"'
                        if ismember(previousChar, '.+-*/\^=~<>&|@,:;([{ ')
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING;
                        else
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION;
                        end
                    case '}'
                        braceDepth = braceDepth - 1;
                        if braceDepth > 0
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION;
                        else
                            expressions{end+1} = buffer;
                            buffer = '';
                            state = IN_LITERAL;
                        end
                    otherwise
                        buffer(end+1) = currentChar;
                        state = IN_EXPRESSION;
                end
            case IN_EXPRESSION_AND_SINGLE_QUOTED_STRING
                switch currentChar
                    case ''''
                        if nextChar == ''''
                            buffer(end+1:end+2) = '''''';
                            i = i + 1;
                            state = IN_EXPRESSION_AND_SINGLE_QUOTED_STRING;
                        elseif ismember(nextChar, '.+-*/\^=~<>&|@,:;()[]{} ')
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION;
                        else
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION_AND_SINGLE_QUOTED_STRING;
                        end
                    otherwise
                        buffer(end+1) = currentChar;
                        state = IN_EXPRESSION_AND_SINGLE_QUOTED_STRING;
                end
            case IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING
                switch currentChar
                    case '"'
                        if nextChar == '"'
                            buffer(end+1:end+2) = '""';
                            i = i + 1;
                            state = IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING;
                        elseif ismember(nextChar, '.+-*/\^=~<>&|@,:;()[]{} ')
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION;
                        else
                            buffer(end+1) = currentChar;
                            state = IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING;
                        end
                    otherwise
                        buffer(end+1) = currentChar;
                        state = IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING;
                end
        end
        i = i + 1;
    end

    switch state
        case IN_LITERAL
            literals{end+1} = buffer;
        case IN_EXPRESSION
            e = MException("FString:unmatchedOpeningCurlyBrace", ...
                "Opening curly brace '{' found without a corresponding closing curly brace '}'.");
            throw(e);
        case IN_EXPRESSION_AND_SINGLE_QUOTED_STRING
            e = MException("FString:unclosedSingleQuotedStringInExpression", ...
                "Opening single quote ' found in expression without a corresponding closing single quote '.");
            throw(e);
        case IN_EXPRESSION_AND_DOUBLE_QUOTED_STRING
            e = MException("FString:unclosedDoubleQuotedStringInExpression", ...
                'Opening double quote " found in expression without a corresponding closing double quote ".');
            throw(e);
    end
end

function formattedLiterals = formatLiteral(literals)
    arguments
        literals (1,:) cell
    end

    formattedLiterals = {};

    for i = 1:numel(literals)
        formattedLiterals{i} = sprintf(replace(literals{i}, {'%', '{{', '}}'},  {'%%', '{', '}'}));
    end
end

function expressionStructs = parseExpression(expressions)
    arguments
        expressions (1,:) cell
    end

    expressionStructs = struct(...
        'expression', '', ...
        'displayedText', '', ...
        'formatSpecifier', '', ...
        'evaluatedValue', {});

    for i = 1:numel(expressions)
        expression = expressions{i};

        colonIndices = strfind(expression, ':');
        if ~isempty(colonIndices)
            lastColonIndex = colonIndices(end);
            expressionStructs(i).formatSpecifier = expression(lastColonIndex+1:end);
            expression = expression(1:lastColonIndex-1);
        end
        
        equalIndices = strfind(expression, '=');
        if ~isempty(equalIndices)
            lastEqualIndex = equalIndices(end);
            for c = expression(lastEqualIndex+1:end)
                if c ~= ' '
                    e = MException("FString:nonSpaceCharAfterEqual", ...
                        "In expression, after '=', there should be only whitespace(s).");
                    throw(e);
                end
            end
            expressionStructs(i).displayedText = expression;
            expression = expression(1:lastEqualIndex-1);
        end

        expressionStructs(i).expression = expression;
    end
end

function formattedExpressions = formatExpression(expressionStructs)
    arguments
        expressionStructs (1,:) struct
    end

    formattedExpressions = {};

    for i = 1:numel(expressionStructs)
        if isempty(expressionStructs(i).formatSpecifier)
            formattedExpression = char(string(expressionStructs(i).evaluatedValue));
        else
            formattedExpression = char(compose(expressionStructs(i).formatSpecifier, expressionStructs(i).evaluatedValue{1}));
        end
        if ~isempty(expressionStructs(i).displayedText)
            formattedExpression = append(expressionStructs(i).displayedText, formattedExpression);
        end
        formattedExpressions{end+1} = formattedExpression;
    end
end

function formattedParts = interlace(formattedLiterals, formattedExpressions)
    arguments
        formattedLiterals (1,:) cell
        formattedExpressions (1,:) cell
    end

    formattedParts = cell(1, numel(formattedLiterals) + numel(formattedExpressions));
    for i = 1:numel(formattedLiterals)
        formattedParts(2*i-1) = formattedLiterals(i);
    end
    for i = 1:numel(formattedExpressions)
        formattedParts(2*i) = formattedExpressions(i);
    end
end
