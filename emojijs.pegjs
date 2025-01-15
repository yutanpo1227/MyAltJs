{
    function makeProgram(body) {
        return {
            type: "Program",
                body,
            sourceType: "script"
        };
    }
        
    function makeExpressionStatement(expression) {
        return {
            type: "ExpressionStatement",
            expression
        };
    }

    function makeConsoleLog(argument) {
        return {
            type: "ExpressionStatement",
            expression: {
                type: "CallExpression",
                callee: {
                    type: "MemberExpression",
                    computed: false,
                    object: {
                        type: "Identifier",
                        name: "console"
                    },
                    property: {
                        type: "Identifier",
                        name: "log"
                    }
                },
                arguments: [ argument ]
            }
        };
    }

    function makeLiteral(value) {
        return {
            type: "Literal",
            value,
            raw: JSON.stringify(value)
        };
    }

    function makeNumberLiteral(value) {
        return {
            type: "Literal",
            value,
            raw: String(value)
        };
    }

    function makeIdentifier(name) {
        return {
            type: "Identifier",
            name
        };
    }

    function makeVariableDeclaration(id, init) {
        return {
            type: "VariableDeclaration",
            declarations: [
                {
                    type: "VariableDeclarator",
                    id,
                    init
                }
            ],
            kind: "let"
        };
    }

    function makeAssignmentExpression(left, right) {
        return {
            type: "ExpressionStatement",
            expression: {
                type: "AssignmentExpression",
                operator: "=",
                left,
                right
            }
        };
    }

    function makeBinaryExpression(operator, left, right) {
        return {
            type: "BinaryExpression",
            operator,
            left,
            right
        };
    }

    function makeLogicalExpression(operator, left, right) {
        return {
            type: "LogicalExpression",
            operator,
            left,
            right
        };
    }

    function makeForStatement(init, test, update, body) {
        return {
            type: "ForStatement",
            init,
            test,
            update,
            body: {
                type: "BlockStatement",
                body
            }
        };
    }

    function makeForOfStatement(left, right, body) {
        return {
            type: "ForOfStatement",
            left,
            right,
            body: {
                type: "BlockStatement",
                body
            }
        };
    }

    function makeIfStatement(test, body, alternate) {
        return {
            type: "IfStatement",
            test,
            consequent: {
                type: "BlockStatement",
                body
            },
            alternate
        };
    }

    function makeElseIfObject(test, body) {
        return {
            type: "ElseIfObject",
            test,
            body
        };
    }

    function makeElseObject(body) {
        return {
            type: "ElseObject",
            body
        };
    }

    function makeBlockStatement(body) {
        return {
            type: "BlockStatement",
            body
        };
    }

    function combineIfChain(ifObj, elseIfs, elseObj) {
        let currentIf = ifObj;
        for (const elif of elseIfs) {
            const newIf = makeIfStatement(elif.test, elif.body, null);
            currentIf.alternate = newIf;
            currentIf = newIf;
        }
        if (elseObj) {
            currentIf.alternate = {
                type: "BlockStatement",
                body: elseObj.body
            };
        }
        return ifObj;
    }
}

Start
    = _ statements:StatementList _
    {
        return makeProgram(statements);
    }

StatementList
    = head:Statement tail:(_ Statement)*
    {
        return [head].concat(
            tail.map(function(item) { return item[1]; })
        );
    }

Statement
    = ConsoleLogStatement
    / VariableDeclarationStatement
    / AssignmentStatement
    / ForStatement
    / ForOfAssignmentStatement
    / IfBlock

ConsoleLogStatement
    = "🖥️" _ expr:Expression _ "✅"
    {
        return makeConsoleLog(expr);
    }

VariableDeclarationStatement
    = "📦" _ id:Identifier _ "🟰" _ val:Expression _ "✅"
    {
        return makeVariableDeclaration(id, val);
    }

AssignmentStatement
    = id:Identifier _ "🟰" _ expr:Expression _ "✅"
    {
        return makeAssignmentExpression(id, expr);
    }

ForStatement
    = "🔁" _ init:ForInit _ cond:Expression _ "✅" _ update:UpdateExpression _ "🔜" _ body:StatementList _ "🔚"
    {
        return makeForStatement(init, cond, update, body);
    }

ForOfAssignmentStatement
    = "🔁" _ "⏏️" _ iterable:Expression _ "➡️" _ loopVar:Identifier _ "🔜" _ body:StatementList _ "🔚" {
        return makeForOfStatement(loopVar, iterable, body);
    }

ForInit
    = "📦" _ id:Identifier _ "🟰" _ val:NumberLiteral _ "✅"
    {
        return makeVariableDeclaration(id, val);
    }

UpdateExpression
    = id:Identifier "➕➕"
    {
        return {
            type: "UpdateExpression",
            operator: "++",
            argument: id,
            prefix: false
        };
    } / id:Identifier "➖➖"
    {
        return {
            type: "UpdateExpression",
            operator: "--",
            argument: id,
            prefix: false
        };
    }

IfBlock
    = ifPart:SingleIfBlock elseIfPart:( _? ElseIfBlock )* elsePart:( _? ElseBlock )? {
            return combineIfChain(ifPart, elseIfPart.map(elif => elif[1]), elsePart ? elsePart[1] : null);
        }

SingleIfBlock
    = "❓" _ test:Expression _ "🔜" _ body:StatementList _ "🔚"
    {
        return makeIfStatement(test, body, null);
    }

ElseIfBlock
    = "⁉️" _ test:Expression _ "🔜" _ body:StatementList _ "🔚"
    {
        return makeElseIfObject(test, body);
    }

ElseBlock
    = "❗️" _ "🔜" _ body:StatementList _ "🔚"
    {
        return makeElseObject(body);
    }

Expression
    = LogicalOrExpression

LogicalOrExpression
    = left:LogicalAndExpression _ "💔" _ right:LogicalOrExpression
        {
            return makeLogicalExpression("||", left, right);
        }
    / LogicalAndExpression

LogicalAndExpression
    = left:EqualityExpression _ "💕" _ right:LogicalAndExpression
        {
            return makeLogicalExpression("&&", left, right);
        }
    / EqualityExpression

EqualityExpression
    = left:ComparisonExpression _ op:("🟰🟰🟰" { return "==="; } / "🟰🟰" { return "=="; }) _ right:ComparisonExpression
        {
            return makeBinaryExpression(op, left, right);
        }
    / ComparisonExpression

ComparisonExpression
    = left:AdditiveExpression _ op:ComparisonOp _ right:AdditiveExpression
        {
            return makeBinaryExpression(op, left, right);
        }
    / AdditiveExpression

ComparisonOp
    = "⏮️" { return "<="; }
    / "⏭️" { return ">="; }
    / "◀️" { return "<"; }
    / "▶️" { return ">"; }

AdditiveExpression
    = left:MultiplicativeExpression _ op:("➕" {return "+";} / "➖" {return "-";}) _ right:AdditiveExpression
        {
            return makeBinaryExpression(op, left, right);
        }
    / MultiplicativeExpression

MultiplicativeExpression
    = left:PrimaryExpression _ op:("✖️" {return "*";} / "➗" {return "/";} / "〰️" {return "%";}) _ right:MultiplicativeExpression
        {
            return makeBinaryExpression(op, left, right);
        }
    / PrimaryExpression

PrimaryExpression
    = ParenthesizedExpression
    / NumberLiteral
    / StringLiteral
    / Identifier

ParenthesizedExpression
    = "(" _ expr:Expression _ ")"
        {
            return expr;
        }

StringLiteral
    = '📝' chars:(!'📝' .)* '📝' 
    {
        const val = text().slice(1, -1);
        return makeLiteral(val.slice(1, -1));
    }

NumberLiteral
    = digits:Digit+
    {
        const str = digits.join("");
        return makeNumberLiteral(parseInt(str, 10));
    }

Digit
    = '0️⃣' { return '0'; }
    / '1️⃣' { return '1'; }
    / '2️⃣' { return '2'; }
    / '3️⃣' { return '3'; }
    / '4️⃣' { return '4'; }
    / '5️⃣' { return '5'; }
    / '6️⃣' { return '6'; }
    / '7️⃣' { return '7'; }
    / '8️⃣' { return '8'; }
    / '9️⃣' { return '9'; }

Identifier
    = chars:([a-zA-Z]+)
    {
        return makeIdentifier(chars.join(""));
    }

_ = 
    (WhiteSpace / Comment)*

WhiteSpace 
    = [ \t\n\r]+

Comment
    = "💬" (![\n\r] .)* ("\n" / !.)