function EEGout = my_fxtrap(EEGin,hp,lp,transition,rectif,smooth,resamp);
%EEGout = EEGout = my_fxtrap(EEGin,hp,lp,transition,rectif,smooth,resamp);
%Filter on EEGlab dataset (EEGin) via frequency domain trapazoidal comb
%function.
%lp = lowpass cutoff
%transition = transition bandwidth
%rectif = rectify [1] no [0]
%smooth = smooth with boxcar of width in ms [value] no [0]
%resamp = resample [value] no [0]

%Error message
if size(EEGin.data,3)>1;
    error('WHY ARE YOU FILTERING DISCONTINUOUS DATA YOU FOOL?!');
end

%Available frequencies
hz = linspace(0,EEGin.srate,size(EEGin.data,2));

%Calcaulate the nyquist and prepare a matrix of inflection points for the
%filter

fx = ones(size(hz));

if lp>0;
lp2 = lp+(transition/2);if lp2>EEGin.srate/2;error('transition too wide for specified lp');end
%Draw a lopass filter
fx(hz>lp2)=0;
fx(hz>=lp & hz<=lp2) = linspace(1,0,sum(hz>=lp & hz<=lp2));
end;

if hp>0;
hp2 = hp-(transition/2);if hp2<0;error('transition too wide for specified hp');end
%Draw a hipass filter
fx(hz<hp2)=0;
fx(hz>=hp2 & hz<=hp) = linspace(0,1,sum(hz>=hp2 & hz<=hp));
end;

fx = (fx+fliplr(fx));
fx = fx-min(fx);

EEGout = EEGin;
%Filter the data and rectify if specified
if rectif ==1;
    EEGout.data = abs(real(ifft(bsxfun(@times,fft(EEGin.data,[],2),fx),[],2)));
else
    EEGout.data = real(ifft(bsxfun(@times,fft(EEGin.data,[],2),fx),[],2));
end

%Smooth the data, if specified
if smooth>0;
    box_ms = smooth;
    box_dp = (EEGout.srate*box_ms)/1000;
    l = ceil(box_dp/2);
    w = 2*l + 1;
    [c,d] = size(EEGout.data);
    paddata = single([zeros(c,l) EEGout.data zeros(c,l)]);
    for wp = 0:w-1;
        if wp ==0;
            smoothdata = paddata(:,1+wp:d+wp);
        else
            smoothdata = smoothdata+paddata(:,1+wp:d+wp);
        end
    end;
    EEGout.data = reshape(smoothdata./w,EEGout.nbchan,[],EEGout.trials);
end

%Resample the data, if specified
if resamp>0;
    EEGout = pop_resample(EEGout,resamp);
end

end