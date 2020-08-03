classdef RoboClawDriver < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    %	RoboClaw Driver for Raspberry Pi
    %
    %	Author : Eisuke Matsuzaki
    %	Created on : 07/21/2020
    %	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
    %	Released under the MIT license
    %
    
    %#codegen
    %#ok<*EMCA>
    
    properties
        % Public, tunable properties.
    end
    
    properties (Nontunable)
        tty = '/dev/ttyACM0' % Device port
        address = '128 (0x80)' % Packet Serial Address
        baudrate = '38400'; % Baudrate (bps)
        timeout = 0; % Timeout (seconds)
        strict_0xFF_ACK = 0; % Strict 0xFF ACK byte
        mode = 'Speed'; % Control Mode
    end
    
    properties(Nontunable, PositiveInteger)
        retries = 30; % retries for connection
    end
    
    properties (Constant, Hidden)
        baudrateSet = matlab.system.StringSet({'2400', '9600', '19200', '38400',...
                                               '57600', '115200', '230400', '460800'});
        addressSet = matlab.system.StringSet({'128 (0x80)', '129 (0x81)', '130 (0x82)', '131 (0x83)',...
                                              '132 (0x84)', '133 (0x85)', '134 (0x86)', '135 (0x87)'});
        modeSet = matlab.system.StringSet({'Duty', 'Speed', 'Speed & Accelaration'});
        inputName = {'M1 Duty', 'M2 Duty', 'M1 Speed', 'M2 Speed', 'Accel'};
        inputType = {'double', 'double', 'double', 'double', 'double'};
        outputName = {'M1 Encoder', 'M2 Encoder', 'Main battery'};
        outputType = {'double', 'double', 'double'};
    end
    
    properties (Access = private)
        addressNum = uint8(0);
        addressName = {'128 (0x80)', '129 (0x81)', '130 (0x82)', '131 (0x83)',...
                       '132 (0x84)', '133 (0x85)', '134 (0x86)', '135 (0x87)'}
        addressVal = uint8([128, 129, 130, 131, 132, 133, 134, 135]);
        baudrateNum = int32(0);
        baudrateName = {'2400', '9600', '19200', '38400', '57600', '115200', '230400', '460800'};
        baudrateVal = int32([2400, 9600, 19200, 38400, 57600, 115200, 230400, 460800]);
        modeId = uint8(0);
        modeName = {'Duty', 'Speed', 'Speed & Accelaration'};
    end
    
    methods
        % Constructor
        function obj = Source(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                coder.cinclude('roboclaw_wrapper.h');
                
                for i = 1:length(obj.addressName)
                    if(strcmp(obj.address, obj.addressName{i}))
                        obj.addressNum = obj.addressVal(i);
                    end
                end
                
                for i = 1:length(obj.baudrateName)
                    if(strcmp(obj.baudrate, obj.baudrateName{i}))
                        obj.baudrateNum = obj.baudrateVal(i);
                    end
                end
                
                for i = 1:length(obj.modeName)
                    if(strcmp(obj.mode, obj.modeName{i}))
                        obj.modeId = uint8(i-1);
                    end
                end
                
                settings = struct('tty', obj.tty,...
                                  'address', obj.addressNum,...
                                  'baudrate', obj.baudrateNum,...
                                  'timeout_ms', int16(obj.timeout * 1000),...
                                  'retries', obj.retries,...
                                  'strict_0xFF_ACK', obj.strict_0xFF_ACK,...
                                  'mode', obj.modeId);
                coder.cstructname(settings, 'struct roboclaw_Settings', 'extern', 'HeaderFile', 'roboclaw_wrapper.h');
                coder.ceval('roboclaw_initialize', coder.ref(settings));
            end
        end
        
        function varargout = stepImpl(obj,varargin)   %#ok<MANU>
            varargout = {0, 0, 0};
            if isempty(coder.target)
                % Place simulation output code here
            else
                % Call C-function implementing device output
                u = zeros(1, 5);
                indexNum = getInputNumIndex(obj);
                for i=1:length(indexNum)
                    u(indexNum(i)) = varargin{i};
                end

                data = struct('m1Duty', int16(u(1)),...
                              'm2Duty', int16(u(2)),...
                              'm1Speed', int32(u(3)),...
                              'm2Speed', int32(u(4)),...
                              'accel', int32(u(5)),...
                              'm1Counts', int32(0),...
                              'm2Counts', int32(0),...
                              'voltage', single(0));
                
                coder.cstructname(data, 'struct roboclaw_Data', 'extern', 'HeaderFile', 'roboclaw_wrapper.h');
                coder.ceval('roboclaw_step', coder.ref(data));
                
                varargout{1} = double(data.m1Counts);
                varargout{2} = double(data.m2Counts);
                varargout{3} = double(data.voltage);
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.ceval('roboclaw_terminate');
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(obj)
            num = sum(getInputIndex(obj));
        end
        
        function num = getNumOutputsImpl(obj)
            num = length(obj.outputName);
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputFixedSizeImpl(obj,~)
            for i = 1:sum(getInputIndex(obj))
                varargout{i} = true;
            end
        end
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            for i = 1:length(obj.outputName)
                varargout{i} = true;
            end
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputComplexImpl(obj)
            for i = 1:sum(getInputIndex(obj))
                varargout{i} = false;
            end
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:length(obj.outputName)
                varargout{i} = false;
            end
        end
        
        function varargout = getInputSizeImpl(obj)
            for i = 1:sum(getInputIndex(obj))
                varargout{i} = [1, 1];
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            for i = 1:length(obj.outputName)
                varargout{i} = [1, 1];
            end
        end
        
        function varargout = getInputDataTypeImpl(obj)
            index = getinputIndex(obj);
            j = 1;
            for i = 1:length(obj.inputType)
                if index(i)
                    varargout{j} = obj.inputType{i};
                    j = j + 1;
                end
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            for i = 1:length(obj.outputName)
                varargout{i} = obj.outputType{i};
            end
        end
        
        function varargout = getInputNamesImpl(obj)
            index = getInputIndex(obj);
            j = 1;
            for i = 1:length(obj.inputName)
                if index(i)
                    varargout{j} = obj.inputName{i};
                    j = j + 1;
                end
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            for i = 1:length(obj.outputName)
                varargout{i} = obj.outputName{i};
            end
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            icon = {'RoboClaw', '', ['Port : ', obj.tty], ['Baudrate : ', obj.baudrate, 'bps']};
        end
        
        function index = getInputIndex(obj)
            switch obj.mode
                case 'Duty'
                    index = [true, true, false, false, false];
                case 'Speed'
                    index = [false, false, true, true, false];
                case 'Speed & Accelaration'
                    index = [false, false, true, true, true];
                otherwise
                    index = [false, false, false, false, false];
            end
        end
        
        function indexNum = getInputNumIndex(obj)
            index = getInputIndex(obj);
            indexNum = zeros(1, sum(index));
            j = 1;
            for i=1:length(index)
               if index(i)
                   indexNum(j) = i;
                   j = j + 1;
               end
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function groups = getPropertyGroupsImpl()
            configGroup = matlab.system.display.Section(...
               'Title', 'General configuration', 'PropertyList', {'tty', 'baudrate', 'mode', 'SampleTime'});
            advanceGroup = matlab.system.display.Section(...
               'Title', 'Advanced setting', 'PropertyList', {'address', 'timeout', 'retries', 'strict_0xFF_ACK'});
            groups = [configGroup, advanceGroup];
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'RoboClaw';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); %#ok<NASGU>
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                addSourceFiles(buildInfo,'roboclaw.c', srcDir);
                addSourceFiles(buildInfo,'roboclaw_wrapper.c', srcDir);
                addLinkFlags(buildInfo,'-lpthread');
            end
        end
    end
end
