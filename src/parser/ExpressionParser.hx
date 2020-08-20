package parser;

import parser.nodes.datatypes.StringN;
import lexer.Lexer;
import parser.nodes.Node;
import parser.nodes.operators.*;
import parser.nodes.Ident;
import lexer.TokenType;
import parser.nodes.Expression;

class ExpressionParser {

    final parser:Parser;
    final lexer:Lexer;

    public function new(parser:Parser, lexer:Lexer) {
        this.parser = parser;
        this.lexer = lexer;
    }

    public function parseExpression():Expression {
        return new Expression(parser.currentToken.line, disjunction());
    }

    function disjunction():Node {
        trace(parser.currentToken.type);
        var left = conjunction();

        while (parser.currentToken.type == TokenType.LogicOr) {
            parser.nextToken();
            final right = conjunction();

            left = new LogicOr(parser.currentToken.line, left, right);
        }

        return left;
    }

    function conjunction():Node {
        var left = comparison();

        while (parser.currentToken.type == TokenType.LogicAnd) {
            parser.nextToken();
            final right = comparison();

            left = new LogicAnd(parser.currentToken.line, left, right);
        }

        return left;
    }

    function comparison():Node {
        final left = numeric();

        return switch (parser.currentToken.type) {
            case TokenType.SmallerThan:
                parser.nextToken();
                final right = numeric();
                new SmallerThan(parser.currentToken.line, left, right);
            case TokenType.GreaterThan:
                parser.nextToken();
                final right = numeric();
                new GreaterThan(parser.currentToken.line, left, right);
            case TokenType.Equal:
                parser.nextToken();
                final right = numeric();
                new Equal(parser.currentToken.line, left, right);
            default: left;
        }
    }

    function numeric():Node {
        var left = term();

        while (parser.currentToken.type == TokenType.Plus || parser.currentToken.type == TokenType.Minus) {
            left = if (parser.currentToken.type == TokenType.Plus) {
                parser.nextToken();
                final right = term();
                new Plus(parser.currentToken.line, left, right);
            } else {
                parser.nextToken();
                final right = term();
                new Minus(parser.currentToken.line, left, right);
            }
        }

        return left;
    }

    function term():Node {
        var left = signedFactor();

        while (parser.currentToken.type == TokenType.Multiply || parser.currentToken.type == TokenType.Divide) {
            left = if (parser.currentToken.type == TokenType.Multiply) {
                parser.nextToken();
                final right = term();
                new Multiply(parser.currentToken.line, left, right);
            } else {
                parser.nextToken();
                final right = term();
                new Divide(parser.currentToken.line, left, right);
            }
        }

        return left;
    }

    function signedFactor():Node {
        final minus = parser.currentToken.type == TokenType.Minus;

        if (minus) {
            parser.nextToken();
        }

        final right = factor();

        return if (minus) {
            new Negation(parser.currentToken.line, right);
        } else right;
    }

    function factor():Node {
        return switch (parser.currentToken.type) {
            case TokenType.LParen:
                parser.nextToken();
                final disjunction = disjunction();

                if (parser.currentToken.type != TokenType.RParen) {
                    Error.unexpectedToken();
                }

                parser.nextToken();

                disjunction;

            case TokenType.Ident:
                final ident = new Ident(parser.currentToken.line, parser.currentToken.literal);
                parser.nextToken();

                if (parser.currentToken.type == TokenType.LParen) {
                    parser.parseCall(new Expression(parser.currentToken.line, ident)).value;
                } else {
                    ident; 
                }

            case TokenType.Number:
                final number = parser.parseNumber();
                parser.nextToken();
                
                number;

            case TokenType.String:
                final string = new StringN(parser.currentToken.line, parser.currentToken.literal);
                parser.nextToken();

                string;

            case TokenType.Function:
                parser.nextToken();
                parser.parseFunction();

            default: new Ident(-1, "");
        }
    }
}