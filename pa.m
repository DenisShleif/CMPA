function [] = pa()
clear
clc
close all
warning off

Vmin = -1.95;
Vmax = 0.7;
N = 200;
err = 0.2;

Is = 0.01e-12; %A
Ib = 0.1e-12; %A
Vb = 1.3; %V
Gp = 0.1; %S
params = [Is,Gp,Ib,Vb];
V = linspace(Vmin,Vmax,N);
I1 = Is*(exp(1.2*V/0.025)-1)+Gp*V-Ib*(exp((-1.2*(V+Vb))/0.025)-1);
I2 = I1.*((1-err)+rand(1,length(V))*2*err);

numFits = [2,3,1];
for n = 1:3
    figure('units','normalized','outerposition',[0 0 1 1])
    [IplotData,legendStrs] = generateFits(V,I1,I2,params,n,numFits);
    plotFits(V,IplotData,legendStrs,numFits,n);
end
end

function [IplotData,legendStrs] = generateFits(V,I1,I2,params,n,numFits)
legendStrs = cell(1,numFits(n)+1);
IplotData = cell(numFits(n)+1,2);
for o = 1:2
    if o == 1
        IAnalze = I1;
    elseif o == 2
        IAnalze = I2;
    end
    for m = 0:numFits(n)
        if m == 0
            Ifit = IAnalze;
            legendStrs{1} = 'Data';
        else
            [Ifit,legendStr] = getFitData(V,IAnalze,params,n,m);
            legendStrs{m+1} = legendStr;
        end
        IplotData{m+1,o} = Ifit;
    end
end
end

function [] = plotFits(V,IplotData,legendStrs,numFits,n)
for k = 1:4
    subplot(2,2,k)
    for m = 1:(numFits(n)+1)
        switch k
            case 1
                plot(V,IplotData{m,1});
            case 2
                plot(V,IplotData{m,2});
            case 3
                semilogy(V,abs(IplotData{m,1}));
            case 4
                semilogy(V,abs(IplotData{m,2}));
        end
        if m == 1
           lims = axis; 
        end
        hold on;
    end
    axis(lims);
    xlabel('Voltage (V)')
    ylabel('Current (A)')
    grid on;
    legend(legendStrs,'Location','southoutside','Orientation','horizontal');
    title(generateTitle(n,k));
end
end

function [out] = generateTitle(n,k)
    if n == 1
        out = 'Polynomial Fits';
    elseif n == 2
        out = 'Curve Fits';
    elseif n == 3
        out = 'Neural Network';
    end
    out = strcat(out,': IV Curve ');
    if k == 1  || k == 3
        out = strcat(out,'(No Random Variation)');
    else
        out = strcat(out,'(With Random Variation)');
    end
end

function [fo,ft,legendStr] = createFitOptions(params,mode)
if mode == 1
    upper = [Inf,params(2),Inf,params(4)];
    lower = [-Inf,params(2),-Inf,params(4)];
    legendStr = 'B and D set';
elseif mode == 2
    upper = [Inf,Inf,Inf,params(4)];
    lower = [-Inf,-Inf,-Inf,params(4)];
    legendStr = 'D set';
else
    upper = [Inf,Inf,Inf,Inf];
    lower = [-Inf,-Inf,-Inf,-Inf];
    legendStr = 'No set';
end
ft = fittype('A.*(exp(1.2*x/25e-3)-1) + B.*x - C*(exp(1.2*(-(x+D))/25e-3)-1)');
fo = fitoptions(ft);
fo = fitoptions(fo,'Lower',lower);
fo = fitoptions(fo,'Upper',upper);
end

function [fitI,legendStr] = getFitData(V,I,params,question,num)
if question == 1
    p = polyfit(V,I,4*num);
    fitI = polyval(p,V);
    legendStr = sprintf('%dth Order Fit',4*num);
elseif question == 2
    [fo,ft,legendStr] = createFitOptions(params,num);
    ff = fit(V',I',ft,fo);
    fitI = ff(V);
elseif question == 3
    inputs = V;
    targets = I;
    hiddenLayerSize = 10;
    net = fitnet(hiddenLayerSize);
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    net = train(net,inputs,targets);
    outputs = net(V);
    %errors = gsubtract(outputs,targets);
    %performance = perform(net,targets,outputs);
    %fprintf('Neural Net Errors: %f\n',errors);
    %fprintf('Neural Net Performance: %f\n',performance);
    legendStr = 'Neural Network Fit';
    fitI = outputs;
end
end