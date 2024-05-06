# F-String

[![Test](https://github.com/Sam-C/fstring/actions/workflows/test.yml/badge.svg)](https://github.com/Sam-C/fstring/actions/workflows/test.yml)

F-String is like `sprintf()`, but more readable and concise. It provides a way to interpolate variables and expressions inside a string for formatting. Simply wrap the expressions in curly braces `{}`, and pass the string to `f()`, and it will return the formatted string. These expressions can include variables, arithmetic operations, function calls, and more.

F-String is inspired by Python [f-strings](https://docs.python.org/3/tutorial/inputoutput.html#formatted-string-literals) (formatted string literals).

# Motivation

While `sprintf()` is handy for string formatting, it can be hard to write and read when there are a lot of variables. F-String is simpler:

```matlab
% sprintf()
sprintf("Product ID: %d, Name: %s, Description: %s, Price: %f, Quantity: %d, Date Added: %s, In Stock: %s", id, name, description, price, quantity, date_added, string(is_in_stock))

% f-string
f("Product ID: {id}, Name: {name}, Description: {description}, Price: {price}, Quantity: {quantity}, Date Added: {date_added}, In Stock: {is_in_stock}")
```

# Usage

- **Variables**: Variables can be directly inserted into f-strings using curly braces.  (By default, they are converted to string with `string()`.)
```matlab
>> name = "F-String";
>> f("Hello {name}!")
ans =
    "Hello F-String!"
```

- **Expressions**: Arithmetic operations and function calls can be included within the curly braces.
```matlab
>> x = 4;
>> f("{1 + sqrt(x)}")
ans =
    "3"
```

- **Arrays, Cell Arrays, Structs**: They can also be included using curly braces.
```matlab
>> myArray = [1,2,3];
>> myCellArray = {'a','b','c'};
>> myStruct.a = 10;
>> myStruct.b = 20;
>> f("{myArray(3)} {myCellArray{3}} {myStruct.a} {myStruct.('b')}")
ans =
    "3 c 10 20"
```

- **Debugging**: F-strings can simplify debugging by printing variable names (or original expressions) along with their values. Simply add `=` specifier after an expression.
```matlab
>> device = 'Sensor1';
>> temperatureC = 25.5;
>> humidity = 70.0;
>> f('Readings {device=}, {temperatureC=}°C, {humidity=}%')
ans =
    'Readings device=Sensor1, temperatureC=25.5°C, humidity=70%'

>> f('{temperatureC * (9/5) + 32 = }°F') % Spaces around = are respected
ans =
    'temperatureC * (9/5) + 32 = 77.9°F'
```

- **Format specifier**: F-strings support advanced formatting options such as specifying type, precision, and field width for the embedded expressions, using MATLAB's [format specifier](https://www.mathworks.com/help/matlab/ref/compose.html#mw_d65b86bf-791c-4d1e-bf9d-c43110c16a96) .
```matlab
>> f('specify hexadecimal format: {12648430:%#X}')
ans =
    'specify hexadecimal format: 0XC0FFEE'

>> f('specify precision: {0.123456789:%0.3f}')
ans =
    'specify precision: 0.123'

>> f('specify field width: {123:%5d}')
ans =
    'specify field width:   123'

>> f('using debugging and format specifier: {22 / 7 = :%0.3f}')
ans =
    'using debugging and format specifier: 22 / 7 = 3.143'
```

- **Print Curly Braces**: To print curly braces,  escape them with double curly braces `{{  }}`. 
```matlab
>> f('text{{text}}text')
ans =
    'text{text}text'
```

- **Special Characters**: To print special characters, use standard MATLAB [escape sequence](https://www.mathworks.com/help/matlab/ref/compose.html#mw_d65b86bf-791c-4d1e-bf9d-c43110c16a96) (see "special characters section). (One exception: % does not need to be escaped.)
```matlab
>> f("1\t2\n3")
ans =
    "1	2
     3"

>> f('unicode heart: \x2665')
ans =
    'unicode heart: ♥'
```

## More

Cells are converted to string with string().
```matlab
>> f("{ {{42}} }")
ans =
    "42"
```

Embedding arrays directly in expressions will fail because it cannot be converted to string with string().
```matlab
>> f("myArray = {[1,2,3]}")
Error using [string](matlab:matlab.lang.internal.introspective.errorDocCallback('string'))  
Conversion from cell failed. Element 1 must be convertible  
to a string scalar.
```

Nested f-string expression will work, as long as inner quotation marks are escaped (the usual MATLAB way):
```matlab
>> f('<a>{ f("<b>{ f(''<c></c>'') }</b>") }</a>')
ans =
    '<a><b><c></c></b></a>'
```

See `FstringTest.m` for more use cases.

See `f.m` source code for how f-string works.

# Installation

Get the source code from either [MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/164711-f-string) or [GitHub](https://github.com/Sam-C/fstring), then place `f.m` somewhere on your MATLAB path.

# Acknowledgement

Thanks to these projects for inspiration:
- [Python Formatted String Literals](https://docs.python.org/3/tutorial/inputoutput.html#formatted-string-literals) for API design
- [MATLAB sprintf()](https://www.mathworks.com/help/matlab/ref/sprintf.html) for API design
- [MATLAB-Language-grammar](https://github.com/mathworks/MATLAB-Language-grammar/blob/master/Matlab.tmbundle/Syntaxes/MATLAB.tmLanguage) for how to parse single and double quoted strings
# License

FString is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
