[TOC]

# 静态代码检查 - 实践二

## 本文目标

* 了解oclint提供的规则


## 分类

* abstract
* basic
* cocoa
* convention
* design
* empty
* migration
* naming
* redundant
* size
* unused


## basic - BrokenOddnessCheckRule

主要是针对 x % 2 == 1 的写法对负数是无效的情况

```c
void example()
{
    if (x % 2 == 1)         // violation
    {
    }

    if (foo() % 2 == 1)     // violation
    {
    }
}
```

```cpp
bool VisitBinaryOperator(BinaryOperator *binaryOperator)
    {
        Expr *leftExpr = binaryOperator->getLHS();
        Expr *rightExpr = binaryOperator->getRHS();
        if (binaryOperator->getOpcode() == BO_EQ && isRemainderEqualsOne(leftExpr, rightExpr))
        {
            addViolation(binaryOperator, this);
        }

        return true;
    }

bool isIntegerLiteral(Expr *expr, int value)
    {
        IntegerLiteral *integerLiteral = dyn_cast_or_null<IntegerLiteral>(expr);
        return integerLiteral && integerLiteral->getValue() == value;
    }

    bool isRemainderWhenDevidingByTwo(Expr *expr)
    {
        BinaryOperator *binaryOperator = dyn_cast_or_null<BinaryOperator>(expr);
        return binaryOperator &&
            binaryOperator->getOpcode() == BO_Rem && isIntegerLiteral(binaryOperator->getRHS(), 2);
    }

    bool isRemainderEqualsOne(Expr *leftExpr, Expr *rightExpr)
    {
        return (isIntegerLiteral(rightExpr, 1) && isRemainderWhenDevidingByTwo(leftExpr)) ||
            (isIntegerLiteral(leftExpr, 1) && isRemainderWhenDevidingByTwo(rightExpr));
    }
```

## basic - Deadcode

无法执行到的代码

```c
void example(id collection)
{
    for (id it in collection)
    {
        continue;
        int i1;                 // dead code
    }
    return;
    int i2;                     // dead code
}
```

```cpp
bool VisitCompoundStmt(const CompoundStmt *compoundStmt)
{
    bool hasBreakPoint = false;
    for (CompoundStmt::const_body_iterator body = compoundStmt->body_begin(),
        bodyEnd = compoundStmt->body_end(); body != bodyEnd; body++)
    {
        const Stmt *bodyStmt = *body;
        if (hasBreakPoint && bodyStmt && !isAnyLabelStmt(*bodyStmt))
        {
            addViolation(bodyStmt, this);
            break;
        }
        // 是否是结束语句
        hasBreakPoint = isAnyReturnStmt(*bodyStmt);
    }
    return true;
}
```

## cocoa - ObjCVerifyProtectedMethodRule

"实现"Protected关键字。定义受保护的方法,不能在子类中调用

```objc
@interface A : NSObject
- (void)foo __attribute__((annotate("oclint:enforce[protected method]")));
@end

@interface B : NSObject
@property (strong, nonatomic) A* a;
@end

@implementation B
- (void)bar {
    [self.a foo]; // calling protected method foo from outside A and its subclasses
}
@end
```

给AST结构添加协商过的内容,然后在遍历时进行检查

```cpp
bool VisitObjCImplementationDecl(ObjCImplementationDecl* decl) {
    const auto interface = decl->getClassInterface();

    if(interface) {
        auto checker = CheckMethodsInsideClass(*interface, *this);
        checker.TraverseDecl(decl);
        const auto violations = checker.getViolations();
        for(auto expr : violations) {
            const auto sourceClass = expr->getMethodDecl()->getClassInterface();

            string description = "calling protected method " +
                expr->getSelector().getAsString() +
                " from outside " + sourceClass->getNameAsString() + " and its subclasses";
            addViolation(expr, this, description);
        }
    }
    return true;
}

namespace {

    class CheckMethodsInsideClass : public RecursiveASTVisitor<CheckMethodsInsideClass>
    {
        private:
            ObjCInterfaceDecl& _container;
            AbstractASTRuleBase& _rule;
            vector<ObjCMessageExpr*> _violations;

        public:
            CheckMethodsInsideClass(ObjCInterfaceDecl& container, AbstractASTRuleBase& rule) :
                _container(container), _rule(rule) {};

        bool VisitObjCMessageExpr(ObjCMessageExpr* expr) {
            const auto method = expr->getMethodDecl();
            if(!declHasEnforceAttribute(method, _rule)) {
                return true;
            }

            const auto interface = expr->getReceiverInterface();
            if(!interface) {
                return true;
            }

            if(!isObjCInterfaceClassOrSubclass(&_container, interface->getNameAsString())) {
                _violations.push_back(expr);
            }

            return true;
        }

        const vector <ObjCMessageExpr*>& getViolations() const {
            return _violations;
        }

    };
}

```

## cocoa - ObjCVerifyMustCallSuperRule

子类重写父类方法必须调用super

```objc
@interface UIView (OCLintStaticChecks)
- (void)layoutSubviews __attribute__((annotate("oclint:enforce[base method]")));
@end

@interface CustomView : UIView
@end

@implementation CustomView

- (void)layoutSubviews {
    // [super layoutSubviews]; is enforced here
}

@end
```

```objc
bool VisitObjCMethodDecl(ObjCMethodDecl* decl) {
    // Save the method name
    string selectorName = decl->getSelector().getAsString();

    // Figure out if anything in the super chain is marked
    if(declRequiresSuperCall(decl)) {
        // If so, start a separate checker to look for method sends just in the method body
        ContainsCallToSuperMethod checker(selectorName);
        checker.TraverseDecl(decl);
        if(!checker.foundSuperCall()) {
            string message = "overridden method " + selectorName + " must call super";
            addViolation(decl, this, message);
        }
    }

    return true;
}

class ContainsCallToSuperMethod : public RecursiveASTVisitor<ContainsCallToSuperMethod>
{
private:
    string _selector;

    // Location to save found ivar accesses
    bool _foundSuperCall;
public:
    explicit ContainsCallToSuperMethod(string selectorString)
        : _selector(std::move(selectorString))
    {
        _foundSuperCall = false;
    }

    bool VisitObjCMessageExpr(ObjCMessageExpr* expr)
    {
        // 检查方法名 + 消息接收者为super
        if(expr->getSelector().getAsString() == _selector
        && expr->getReceiverKind() == ObjCMessageExpr::SuperInstance) {
            _foundSuperCall = true;
        }
        return true;
    }

    bool foundSuperCall() const {
        return _foundSuperCall;
    }
};
```

## size - LongLineRule

```cpp
class LongLineRule : public AbstractSourceCodeReaderRule
{
    virtual void eachLine(int lineNumber, string line) override
    {
        int threshold = RuleConfiguration::intForKey("LONG_LINE", 100);
        int currentLineSize = line.size();
        if (currentLineSize > threshold)
        {
            string description = "Line with " + toString<int>(currentLineSize) +
                " characters exceeds limit of " + toString<int>(threshold);
            addViolation(lineNumber, 1, lineNumber, currentLineSize, this, description);
        }
    }
}
```

## size - TooManyFieldsRule


```cpp
class TooManyFieldsRule : public AbstractASTVisitorRule<TooManyFieldsRule>
{
    virtual void setUp() override
    {
        _threshold = RuleConfiguration::intForKey("TOO_MANY_FIELDS", 20);
    }

    bool VisitObjCInterfaceDecl(ObjCInterfaceDecl *decl)
    {
        int fieldCount = decl->ivar_size();
        if (fieldCount > _threshold)
        {
            string description = "Objective-C interface with " +
                toString<int>(fieldCount) + " fields exceeds limit of " + toString<int>(_threshold);
            addViolation(decl, this, description);
        }
        return true;
    }

    bool VisitCXXRecordDecl(CXXRecordDecl *decl)
    {
        int fieldCount = distance(decl->field_begin(), decl->field_end());
        if (fieldCount > _threshold)
        {
            string description = "C++ class with " +
                toString<int>(fieldCount) + " fields exceeds limit of " + toString<int>(_threshold);
            addViolation(decl, this, description);
        }
        return true;
    }
}
```

## design - GotoStatementRule


主要为说明 AbstractASTMatcherRule 如何使用

```cpp
class GotoStatementRule : public AbstractASTMatcherRule
{
virtual void callback(const MatchFinder::MatchResult& result) override
    {
        addViolation(result.Nodes.getNodeAs<GotoStmt>("gotoStmt"), this);
    }

    virtual void setUpMatcher() override
    {
        addMatcher(gotoStmt().bind("gotoStmt"));
    }
}
```

