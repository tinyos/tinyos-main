# Copyright (c) 2006-2007 Chad Metcalf <chad@5secondfuse.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Author: Chad Metcalf <chad@5secondfuse.com>
#

"""
A Python Singleton mixin class that makes use of some of the ideas
found at http://c2.com/cgi/wiki?PythonSingleton. Just inherit
from it and you have a singleton. No code is required in
subclasses to create singleton behavior -- inheritance from 
Singleton is all that is needed.

Assume S is a class that inherits from Singleton. Useful behaviors
are:

1) Getting the singleton:

    S.getInstance() 
    
returns the instance of S. If none exists, it is created. 

2) The usual idiom to construct an instance by calling the class, i.e.

    S()
    
is disabled for the sake of clarity. If it were allowed, a programmer
who didn't happen  notice the inheritance from Singleton might think he
was creating a new instance. So it is felt that it is better to
make that clearer by requiring the call of a class method that is defined in
Singleton. An attempt to instantiate via S() will restult in an SingletonException
being raised.

3) If S.__init__(.) requires parameters, include them in the
first call to S.getInstance(.). If subsequent calls have parameters,
a SingletonException is raised.

4) As an implementation detail, classes that inherit 
from Singleton may not have their own __new__
methods. To make sure this requirement is followed, 
an exception is raised if a Singleton subclass includ
es __new__. This happens at subclass instantiation
time (by means of the MetaSingleton metaclass.

By Gary Robinson, grobinson@transpose.com. No rights reserved -- 
placed in the public domain -- which is only reasonable considering
how much it owes to other people's version which are in the
public domain. The idea of using a metaclass came from 
a  comment on Gary's blog (see 
http://www.garyrobinson.net/2004/03/python_singleto.html#comments). 
Other improvements came from comments and email from other
people who saw it online. (See the blog post and comments
for further credits.)

Not guaranteed to be fit for any particular purpose. Use at your
own risk. 
"""

class SingletonException(Exception):
    def __init__(self, *args):
        Exception.__init__(self)
        self.args = args

class MetaSingleton(type):
    def __new__(metaclass, strName, tupBases, dict):
        if dict.has_key('__new__'):
            raise SingletonException, 'Can not override __new__ in a Singleton'
        return super(MetaSingleton,metaclass).__new__(metaclass, strName, tupBases, dict)
        
    def __call__(cls, *lstArgs, **dictArgs):
        raise SingletonException, 'Singletons may only be instantiated through getInstance()'
        
class Singleton(object):
    __metaclass__ = MetaSingleton
    
    def getInstance(cls, *lstArgs):
        """
        Call this to instantiate an instance or retrieve the existing instance.
        If the singleton requires args to be instantiated, include them the first
        time you call getInstance.        
        """
        if cls._isInstantiated():
            if len(lstArgs) != 0:
                raise SingletonException, 'If no supplied args, singleton must already be instantiated, or __init__ must require no args'
        else:
            if cls._getConstructionArgCountNotCountingSelf() > 0 and len(lstArgs) <= 0:
                raise SingletonException, 'If the singleton requires __init__ args, supply them on first instantiation'
            instance = cls.__new__(cls)
            instance.__init__(*lstArgs)
            cls.cInstance = instance
        return cls.cInstance
    getInstance = classmethod(getInstance)
    
    def _isInstantiated(cls):
        return hasattr(cls, 'cInstance')
    _isInstantiated = classmethod(_isInstantiated)  

    def _getConstructionArgCountNotCountingSelf(cls):
        return cls.__init__.im_func.func_code.co_argcount - 1
    _getConstructionArgCountNotCountingSelf = classmethod(_getConstructionArgCountNotCountingSelf)

    def _forgetClassInstanceReferenceForTesting(cls):
        """
        This is designed for convenience in testing -- sometimes you 
        want to get rid of a singleton during test code to see what
        happens when you call getInstance() under a new situation.
        
        To really delete the object, all external references to it
        also need to be deleted.
        """
        try:
            delattr(cls,'cInstance')
        except AttributeError:
            # run up the chain of base classes until we find the one that has the instance
            # and then delete it there
            for baseClass in cls.__bases__: 
                if issubclass(baseClass, Singleton):
                    baseClass._forgetClassInstanceReferenceForTesting()
    _forgetClassInstanceReferenceForTesting = classmethod(_forgetClassInstanceReferenceForTesting)
    


if __name__ == '__main__':
    import unittest
    
    class PublicInterfaceTest(unittest.TestCase):
        def testReturnsSameObject(self):
            """
            Demonstrates normal use -- just call getInstance and it returns a singleton instance
            """
        
            class A(Singleton): 
                def __init__(self):
                    super(A, self).__init__()
                    
            a1 = A.getInstance()
            a2 = A.getInstance()
            self.assertEquals(id(a1), id(a2))
            
        def testInstantiateWithMultiArgConstructor(self):
            """
            If the singleton needs args to construct, include them in the first
            call to get instances.
            """
                    
            class B(Singleton): 
                    
                def __init__(self, arg1, arg2):
                    super(B, self).__init__()
                    self.arg1 = arg1
                    self.arg2 = arg2

            b1 = B.getInstance('arg1 value', 'arg2 value')
            b2 = B.getInstance()
            self.assertEquals(b1.arg1, 'arg1 value')
            self.assertEquals(b1.arg2, 'arg2 value')
            self.assertEquals(id(b1), id(b2))
            
            
        def testTryToInstantiateWithoutNeededArgs(self):
            
            class B(Singleton): 
                    
                def __init__(self, arg1, arg2):
                    super(B, self).__init__()
                    self.arg1 = arg1
                    self.arg2 = arg2

            self.assertRaises(SingletonException, B.getInstance)
            
        def testTryToInstantiateWithoutGetInstance(self):
            """
            Demonstrates that singletons can ONLY be instantiated through
            getInstance, as long as they call Singleton.__init__ during construction.
            
            If this check is not required, you don't need to call Singleton.__init__().
            """

            class A(Singleton): 
                def __init__(self):
                    super(A, self).__init__()
                    
            self.assertRaises(SingletonException, A)
            
        def testDontAllowNew(self):
        
            def instantiatedAnIllegalClass():
                class A(Singleton): 
                    def __init__(self):
                        super(A, self).__init__()
                        
                    def __new__(metaclass, strName, tupBases, dict):
                        return super(MetaSingleton,metaclass).__new__(metaclass, strName, tupBases, dict)
                                        
            self.assertRaises(SingletonException, instantiatedAnIllegalClass)
        
        
        def testDontAllowArgsAfterConstruction(self):
            class B(Singleton): 
                    
                def __init__(self, arg1, arg2):
                    super(B, self).__init__()
                    self.arg1 = arg1
                    self.arg2 = arg2

            b1 = B.getInstance('arg1 value', 'arg2 value')
            self.assertRaises(SingletonException, B, 'arg1 value', 'arg2 value')
            
        def test_forgetClassInstanceReferenceForTesting(self):
            class A(Singleton): 
                def __init__(self):
                    super(A, self).__init__()
            class B(A): 
                def __init__(self):
                    super(B, self).__init__()
                    
            # check that changing the class after forgetting the instance produces
            # an instance of the new class
            a = A.getInstance()
            assert a.__class__.__name__ == 'A'
            A._forgetClassInstanceReferenceForTesting()
            b = B.getInstance()
            assert b.__class__.__name__ == 'B'
            
            # check that invoking the 'forget' on a subclass still deletes the instance
            B._forgetClassInstanceReferenceForTesting()
            a = A.getInstance()
            B._forgetClassInstanceReferenceForTesting()
            b = B.getInstance()
            assert b.__class__.__name__ == 'B'

    unittest.main()
