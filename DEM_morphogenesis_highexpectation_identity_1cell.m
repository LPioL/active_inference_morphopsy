function DEM = DEM_morphogenesis

 
 
% preliminaries
%--------------------------------------------------------------------------
clear global
rng('default')
SPLIT    = 0;                              % split: 1 = upper, 2 = lower
N        = 32;                             % length of process (bins)
 
% generative process and model
%==========================================================================
M(1).E.d  = 1;                             % approximation order
M(1).E.n  = 2;                             % embedding order
M(1).E.s  = 1;                             % smoothness
 
% priors (prototype)
%--------------------------------------------------------------------------
L     = 2;
if L == 2
    T =[0 0 2 0 0 0 0 0 0 0 0;
        0 0 0 0 1 0 0 0 0 0 0;
        2 0 0 0 0 0 4 0 4 0 3;
        0 0 0 0 1 0 0 0 0 0 0;
        0 0 2 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0];
end
 
if L == 4
    T =[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 2 0 0 0 3 0 0 0 0 0 0 0 0 0 0;
        0 0 0 2 0 0 0 0 0 3 0 0 0 4 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 4 0 4 0 1 0 0;
        0 0 0 2 0 0 0 0 0 3 0 0 0 4 0 0 0 0 0 0 0 1;
        0 0 0 0 0 0 0 2 0 0 0 3 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
end
 
     
p(:,:,1) = T > 0;
p(:,:,2) = T == 2 | T == 1;
p(:,:,3) = T == 3 | T == 1;
p(:,:,4) = T == 4;
 
[y,x] = find(p(:,:,1));
P.x   = spm_detrend([x(:) y(:)])'/2; 
 
% signalling of each cell type
%--------------------------------------------------------------------------
n     = size(P.x,2);                      % number of cells
m     = size(p,3);                        % number of signals
j     = find(p(:,:,1));
for i = 1:m
    s        = p(:,:,i);
    P.s(i,:) = s(j);
end
P.s   = double(P.s);
P.c   = morphogenesis(P.x,P.s);           % signal sensed at each position
 
% initialise action and expectations
%--------------------------------------------------------------------------
v     = [          
        -2.2588   -1.3499    1.4090    0.7269   -2.9443    0.3192   0.8884    1.3703
         0.8622    3.0349    1.4172   -0.3034    1.4384    0.3129    0.2939    0.3252
         0.3188    0.7254    0.6715    0.2939    0.3252   -0.8649   1.3703   -0.1649
         exp(6)    0.3462    0.1862    0.1293   -0.1012   -0.0302    0.1387    0.0464
         exp(6)    0.0907    0.0839    0.0367    0.0406   -0.1081   -0.1518   -0.1361
         -0.4336    0.7147    0.7172    0.8884    1.3703   -0.1649   0.7269   -2.9443
         0.3426   -0.2050    1.6302   -1.1471   -1.7115    0.6277    0.7254    0.6715
    0.2292    0.3462    0.1862    0.1293   -0.1012   -0.0302    0.1387    0.0464
];                     % states (identity)
g     = Mg([],v,P);
a.x   = g.x;                              % action (chemotaxis)
a.s   = g.s;                              % action (signal release)
 
 
% generative process 
%==========================================================================
R     = spm_cat({kron(eye(n,n),ones(2,2)) []; [] kron(eye(n,n),ones(4,4));
                 kron(eye(n,n),ones(4,2)) kron(eye(n,n),ones(4,4))});

% level 1 of generative process
%--------------------------------------------------------------------------
G(1).g  = @(x,v,a,P) Gg(x,v,a,P);
G(1).v  = Gg([],[],a,a);
G(1).V  = exp(16);                         % precision (noise)
G(1).U  = exp(2);                          % precision (action)
G(1).R  = R;                               % restriction matrix
G(1).pE = a;                               % form (action)
 
 
% level 2; causes (action)
%--------------------------------------------------------------------------
G(2).a  = spm_vec(a);                      % endogenous cause (action)
G(2).v  = 0;                               % exogenous  cause
G(2).V  = exp(16);
 
 
% generative model
%==========================================================================
 
% level 1 of the generative model: 
%--------------------------------------------------------------------------
M(1).g  = @(x,v,P) Mg([],v,P);
M(1).v  = g;
M(1).V  = exp(3);
M(1).pE = P;
 
% level 2: 
%--------------------------------------------------------------------------
M(2).v  = v;
M(2).V  = exp(-2);
 
 
% hidden cause and prior identity expectations (and time)
%--------------------------------------------------------------------------
U     = zeros(n*n,N);
C     = zeros(1,N);
 
% assemble model structure
%--------------------------------------------------------------------------
DEM.M = M;
DEM.G = G;
DEM.C = C;
DEM.U = U;
 
% solve
%==========================================================================
DEM   = spm_ADEM(DEM);
spm_DEM_qU(DEM.qU,DEM.pU);


% split half simulations
%==========================================================================
if SPLIT
    
    % select (partially diferentiated cells to duplicate
    %----------------------------------------------------------------------
    t    = 8;
    v    = spm_unvec(DEM.pU.v{1}(:,t),DEM.M(1).v);
    if SPLIT > 1
        [i j] = sort(v.x(1,:), 'ascend');
    else
        [i j] = sort(v.x(1,:),'descend');
    end
    j    = [j(1:n/2) j(1:n/2)];
    
    % reset hidden causes and expectations
    %----------------------------------------------------------------------
    v    = spm_unvec(DEM.qU.v{2}(:,t),DEM.M(2).v);
    g    = spm_unvec(DEM.qU.v{1}(:,t),DEM.M(1).v);
    a    = spm_unvec(DEM.qU.a{2}(:,t),DEM.G(1).pE);
    
    v    = v(:,j);
    g.x  = g.x(:,j);
    g.s  = g.s(:,j);
    g.c  = g.c(:,j);
    a.x  = a.x(:,j) + randn(size(a.x))/512;
    a.s  = a.s(:,j) + randn(size(a.s))/512;
    
    DEM.M(1).v = g;
    DEM.M(2).v = v;
    DEM.G(2).a = spm_vec(a);
    
    % solve
    %----------------------------------------------------------------------
    DEM   = spm_ADEM(DEM);
    spm_DEM_qU(DEM.qU,DEM.pU);
    
end



 
% Graphics
%==========================================================================
 
% expected signal concentrations
%--------------------------------------------------------------------------
subplot(2,2,2); cla
A     = max(abs(P.x(:)))*3/2;
h     = 2/3;
 
x     = linspace(-A,A,32);
[x,y] = ndgrid(x,x);
x     = spm_detrend([x(:) y(:)])';
c     = morphogenesis(P.x,P.s,x);
c     = c - min(c(:));
c     = c/max(c(:));
for i = 1:size(c,2)
    col = c(end - 2:end,i);
    plot(x(2,i),x(1,i),'.','markersize',32,'color',col); hold on
end
 
title('target signal','Fontsize',16)
xlabel('location')
ylabel('location')
set(gca,'Color','k');
axis([-1 1 -1 1]*A*(1+1/16))
axis square, box off
 
 
% free energy and expectations
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 1'); clf
colormap pink
subplot(2,2,1); cla
 
plot(-DEM.J)
title('Free energy','Fontsize',16)
xlabel('time')
ylabel('Free energy')
axis square tight
grid on
 
subplot(2,2,2); cla
v      = spm_unvec(DEM.qU.v{2}(:,end),DEM.M(2).v);
[i j]  = max(v);
v(:,j) = v;
imagesc(spm_softmax(v))
title('softmax expectations','Fontsize',16)
xlabel('cell')
ylabel('cell')
axis square tight
 
 
% target morphology
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 2'); clf

subplot(2,2,1); cla
for i = 1:m
    for j = 1:n
        x = P.x(2,j);
        y = P.x(1,j) + i/6;
        if P.s(i,j)
            plot(x,y,'.','markersize',24,'color','k'); hold on
        else
            plot(x,y,'.','markersize',24,'color','c'); hold on
        end
    end
end
xlabel('cell')
title('Encoding','Fontsize',16)
axis image off
hold off
 
subplot(2,2,2); cla
for i = 1:n
    x = P.x(:,i);
    c = P.s(end - 2:end,i);
    c = full(max(min(c,1),0));
    plot(x(2),x(1),'.','markersize',16,'color',c);   hold on
    plot(x(2),x(1),'h','markersize',12,'color',h*c); hold on
end
 
title('morphogenesis','Fontsize',16)
xlabel('location')
ylabel('location')
set(gca,'Color','k');
axis([-1 1 -1 1]*A)
axis square, box off
hold off
 
 
% graphics
%--------------------------------------------------------------------------
subplot(2,2,3); cla;
for t = 1:N
    v = spm_unvec(DEM.qU.a{2}(:,t),a);
    for i = 1:n
        x = v.x(1,i);
        c = v.s(end - 2:end,i);
        c = full(max(min(c,1),0));
        plot(t,x,'.','markersize',16,'color',c); hold on
    end
end
 
title('morphogenesis','Fontsize',16)
xlabel('time')
ylabel('location')
set(gca,'Color','k');
set(gca,'YLim',[-1 1]*A)
axis square, box off
hold off
 
% movies
%--------------------------------------------------------------------------
subplot(2,2,4);hold off, cla;
for t = 1:N
    v = spm_unvec(DEM.qU.a{2}(:,t),a);
    
    for i = 1:n
        x = v.x(:,i);
        c = v.s(end - 2:end,i);
        c = max(min(c,1),0);
        plot(x(2),x(1),'.','markersize',8,'color',full(c)); hold on
        
        % destination
        %------------------------------------------------------------------
        if t == N
            plot(x(2),x(1),'.','markersize',16,'color',full(c));   hold on
            plot(x(2),x(1),'h','markersize',12,'color',full(h*c)); hold on
        end
    end
    set(gca,'Color','k');
    axis square, box off
    axis([-1 1 -1 1]*A)
    drawnow
    
    % save
    %----------------------------------------------------------------------
    Mov(t) = getframe(gca);
    
end
 
set(gca,'Userdata',{Mov,8})
set(gca,'ButtonDownFcn','spm_DEM_ButtonDownFcn')
title('Extrinsic (left click for movie)','FontSize',16)
xlabel('location') 
 
return
 
 
% Equations of motion and observer functions
%==========================================================================
 
% sensed signal
%--------------------------------------------------------------------------
function c = morphogenesis(x,s,y)
% x - location of cells
% s - signals released
% y - location of sampling [default: x]
%__________________________________________________________________________
 
% preliminaries
%--------------------------------------------------------------------------
if nargin < 3; y = x; end                  % sample locations
n     = size(y,2);                         % number of locations
m     = size(s,1);                         % number of signals
k     = 1;                                 % signal decay over space 
c     = zeros(m,n);                        % signal sensed at each location
for i = 1:n
    for j = 1:size(x,2)
        
        % distance
        %------------------------------------------------------------------
        d      = y(:,i) - x(:,j);
        d      = sqrt(d'*d);
        
        % signal concentration
        %------------------------------------------------------------------
        c(:,i) = c(:,i) + exp(-k*d).*s(:,j);
 
    end
end
 
 
% first level process: generating input
%--------------------------------------------------------------------------
function g = Gg(x,v,a,P)
global t
if isempty(t);
    s = 0;
else
    s = (1 - exp(-t*2));
end
a        = spm_unvec(a,P);

g.x(1,:) = a.x(1,:);                     % position  signal
g.x(2,:) = a.x(2,:);                     % position  signal
g.s      = a.s;                          % intrinsic signal
g.c      = s*morphogenesis(a.x,a.s);     % extrinsic signal
 
% first level model: mapping hidden causes to sensations
%--------------------------------------------------------------------------
function g = Mg(x,v,P)
global t
if isempty(t);
    s = 0;
else
    s = (1 - exp(-t*2));
end

p    = spm_softmax(v);                   % expected identity

g.x  = P.x*p;                            % position
g.s  = P.s*p;                            % intrinsic signal
g.c  = s*P.c*p;                          % extrinsic signal

