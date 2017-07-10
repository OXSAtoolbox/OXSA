% Demonstration of the use of variables with nested function
% scope inside a class.

classdef testNestedVarsClass < handle
    properties
        hFig
    end
    
    methods
        function obj = testNestedVarsClass()
            myCount = 0;
            
            obj.hFig = figure;
            clf
            
            uicontrol('Style','pushbutton','String','+1','Callback',@testNestedVarsClass_CB);
            
            return
            
            function testNestedVarsClass_CB(varargin)
                myCount = myCount + 1;
                fprintf('myCount = %d\n',myCount);
            end
        end
    end
end
