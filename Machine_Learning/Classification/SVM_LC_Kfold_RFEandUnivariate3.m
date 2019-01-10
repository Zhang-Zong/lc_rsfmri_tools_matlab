function [AUC_best, Accuracy_best,Sensitivity_best,Specificity_best] =...
    SVM_LC_Kfold_RFEandUnivariate3(opt,data,label)
%=====================SVM classification using RFE=========================
%ע�⣺
% �˴��뱣���Ȩ��ͼΪN-fold��consensus��ƽ��Ȩ��ͼ��refer to��Multivariate classification of social anxiety disorder
% using whole brain functional connectivity����
% ����fitclinear��indices������ԣ�ÿ�εĽ�������в��죡����
%�ڿ�ʼRFE֮ǰ���Լ��뵥�������������ˣ���F-score ��opt.Kendall Tau��Two-sample t-test��
%refer to PMID:18672070opt.Initial_FeatureQuantity
%input��opt.K=opt.K-fold cross validation,opt.K<=N;
%[opt.Initial_FeatureQuantity,opt.Max_FeatureQuantity,opt.Step_FeatureQuantity]=��ʼ��������,���������,ÿ�����ӵ���������
%opt.P_threshold Ϊ�����������������ǵ�P��ֵ;opt.percentage_consensusΪ��
% opt.K fold��ĳ��Ȩ�ز�Ϊ������س��ֵĸ��ʣ���opt.percentage_consensus=0.8��opt.K=5�������5*0.8=4�����ϵ����ز���Ϊ��consensus���ء�
%output����������Լ�opt.K-fold��ƽ������Ȩ��
%performances(:,1:size(performances,2)/2)=���ܣ����µ�Ϊ��׼�
%indices= ������� Ϊ����С��Χ�ڲ���
% path=pwd;
% addpath(path);
msgbox('����fitclinear��indices������ԣ�ÿ�εĽ�������в��죡����')
%% set options
if nargin<1
    opt.K=5;opt.Initial_FeatureQuantity=50;opt.Max_FeatureQuantity=5000;opt.Step_FeatureQuantity=50;%uter opt.K fold.
    opt.P_threshold=0.05;% univariate feature filter.
    opt.learner='svm';opt.stepmethod='percentage';opt.step=10;% RFE.
    opt.percentage_consensus=0.7;%The most frequent voxels/features;range=(0,1];
    opt.weight=1;opt.viewperformance=1;opt.saveresults=1;
    opt.standard='normalizing';opt.min_scale=0;opt.max_scale=1;
    opt.permutation=0;
end
%% ===transform .nii/.img into .mat data, and achive corresponding label=========
if nargin<2 %������û������򲻶�ͼ����������һ������ṩ
    [name_patients,path,data_patients ] = Img2Data_LC;
    [name_controls,~,data_controls ] = Img2Data_LC;
    data=cat(4,data_patients,data_controls);%data
    n_patients=size(data_patients,4);
    n_controls=size(data_controls,4);
    %
    if opt.permutation;disp(['number of patients and controls are ', num2str([n_patients, n_controls])]);end
end
if nargin<3
    label=[ones(n_patients,1);zeros(n_controls,1)];%label
    %     rowrank = randperm(length(label))';
    %     label =label(rowrank,:);%�����label
end
[dim1,dim2,dim3,N]=size(data);
%% ==========just opt.Keep data in inmasopt.K========================
data=reshape(data,[dim1*dim2*dim3,N]);%�з���Ϊ��������ÿһ��Ϊһ��������ÿһ��Ϊһ������
implicitmask = sum(data,2)~=0;%�ڲ�masopt.K,�����ۼ�
data_inmask=data(implicitmask,:);%�ڲ�masopt.K�ڵ�data
data_inmask=data_inmask';
data_inmask_p=data_inmask(label==1,:);
data_inmask_c=data_inmask(label==0,:);
%% ==================ȷ��t�������ܳ��ֵ���С��������================
Num_FeatureSet_min=Inf;
IfLoadIndices=input(['�Ƿ��������еĽ�����֤��ʽ:',char(10),'�� ������ 1',char(10),...
    '�� ������ 0',char(10),'�����룺'],'s');
IfLoadIndices=str2double(IfLoadIndices);
if IfLoadIndices==0
    indices = crossvalind('Kfold', N, opt.K);%�˴�����������ӵ���ƣ����ÿ�ν�����ǲ�һ����
    indices_p = crossvalind('Kfold', n_patients, opt.K);%�˴�����������ӵ���ƣ����ÿ�ν�����ǲ�һ����
    indices_c = crossvalind('Kfold', n_controls, opt.K);%�˴�����������ӵ���ƣ����ÿ�ν�����ǲ�һ����
else
    [file_name_indices,path_source_indices,~] = uigetfile({'*.mat;','All Image Files';...
        '*.*','All Files'},'MultiSelect','off','��ѡ��*MVPA.mat');
    indices_structure=load([path_source_indices,char(file_name_indices)]);
    indices=indices_structure.indices;
    indices_p=indices_structure.indices_p;
    indices_c=indices_structure.indices_c;
end
% ȷ���ļ�����˳��Ϊ����ȷ����Щ�������಻����׼��
loc_name_controls=[];
loc_name_patients=[];
for i=1:opt.K
    loc_name_patients=[loc_name_patients;find(indices_p==i)];
    loc_name_controls=[loc_name_controls;find(indices_c==i)];
end
name_patients_sorted=name_patients(loc_name_patients)';
name_controls_sorted=name_controls(loc_name_controls)';
f_p=@(x) strcat('P_',x);
f_c=@(x) strcat('C_',x);
name_patients_sorted=cellfun(f_p,name_patients_sorted,'UniformOutput',false);
name_controls_sorted=cellfun(f_c,name_controls_sorted,'UniformOutput',false);
name_all_sorted=[name_patients_sorted;name_controls_sorted];
%����˶δ����������
for i=1:opt.K
    %% �����ݷֳ�ѵ�������Ͳ����������ֱ�ӻ��ߺͶ������г�ȡ��Ŀ����Ϊ������ƽ�⣩
    % patients data
    Test_index_p = (indices_p == i); Train_index_p = ~Test_index_p;
    Test_data_p =data_inmask_p(Test_index_p,:);Train_data_p =data_inmask_p(Train_index_p,:);
    % controls data
    Test_index_c = (indices_c == i); Train_index_c = ~Test_index_c;
    Test_data_c =data_inmask_c(Test_index_c,:);Train_data_c =data_inmask_c(Train_index_c,:);
    % all data
    Train_data=[Train_data_p;Train_data_c];
    Test_data=[Test_data_p;Test_data_c];
    % all label
    %     Test_label = [ones(sum(indices_p==i),1);zeros(sum(indices_c==i),1)];
    Train_label =  [ones(sum(indices_p~=i),1);zeros(sum(indices_c~=i),1)];
    %% step2�� ��׼�����߹�һ��
    if strcmp(opt.standard,'normalizing')
        MeanValue = mean(Train_data);
        StandardDeviation = std(Train_data);
        [row_quantity, columns_quantity] = size(Train_data);
        Train_data_temp=zeros(row_quantity, columns_quantity);
        for ii = 1:columns_quantity
            if StandardDeviation(ii)
                Train_data_temp(:, ii) = (Train_data(:, ii) - MeanValue(ii)) / StandardDeviation(ii);
            end
        end
        Test_data_temp = (Test_data - MeanValue) ./ StandardDeviation;
        Train_data=Train_data_temp;Test_data=Test_data_temp;
    end
    
    if strcmp(opt.standard,'scale')
        [Train_data_temp,PS] = mapminmax(Train_data');
        Train_data_temp=Train_data_temp';
        Test_data_temp = mapminmax('apply',Test_data',PS);
        Test_data_temp =Test_data_temp';
        Train_data=Train_data_temp;
        %         Test_data=Test_data_temp;
    end
    
    % ���뵥��������������
    [~,P,~,~]=ttest2(Train_data(Train_label==1,:), Train_data(Train_label==0,:),'Tail','both');
    Index_ttest2=find(P<=opt.P_threshold);
    if ~opt.permutation
        disp(['Number of remained feature of the ',num2str(i),'it ','fold',' = ',num2str(numel(Index_ttest2))]);
    end
    if Num_FeatureSet_min>=numel(Index_ttest2)
        Num_FeatureSet_min=numel(Index_ttest2);
    end
end

%% ==============�����С����С��Ԥ����������,�����������Ϊt�����г��ֵ���С����������Ӧ�Ĳ�������ʵҲ�ı�========
if Num_FeatureSet_min< opt.Max_FeatureQuantity
    if ~opt.permutation
        disp(['t������������Ŀ�����趨���������������ִ�и�����С�������ĳ�����С����Ϊ��',num2str(Num_FeatureSet_min)]);
    end
    opt.Initial_FeatureQuantity=10;opt.Step_FeatureQuantity=floor(Num_FeatureSet_min/100);opt.Max_FeatureQuantity=Num_FeatureSet_min;
end
%% =======================Ԥ����ռ�===============================
Num_FeatureSet=length(opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity);
Accuracy=zeros(opt.K,Num_FeatureSet);Sensitivity =zeros(opt.K,Num_FeatureSet);Specificity=zeros(opt.K,Num_FeatureSet);
AUC=zeros(opt.K,Num_FeatureSet);Decision=cell(opt.K,Num_FeatureSet);PPV=zeros(opt.K,Num_FeatureSet); NPV=zeros(opt.K,Num_FeatureSet);
W_M_Brain=zeros(Num_FeatureSet,dim1*dim2*dim3);%��ͬ�����Ӽ�ʱƽ����weight��outer opt.K-fold��ƽ����
W_Brain=zeros(Num_FeatureSet,sum(implicitmask),opt.K);
label_ForPerformance=cell(opt.K,1);
predict_label=cell(opt.K,Num_FeatureSet);
Predict=NaN(opt.K,N,1);
%%  ====================K fold loop===============================
h1=waitbar(0,'��ȴ� Outer Loop>>>>>>>>','Position',[50 50 280 60]);
switch opt.K<N %opt.K-fold or LOOCV
    case 1
        for i=1:opt.K %Outer opt.K-fold + Inner RFE
            waitbar(i/opt.K,h1,sprintf('%2.0f%%', i/opt.K*100)) ;
            % step1��split data into training data and testing  data
            % �����ݷֳ�ѵ�������Ͳ����������ֱ�ӻ��ߺͶ������г�ȡ��Ŀ����Ϊ������ƽ�⣩
            % patients data
            Test_index_p = (indices_p == i); Train_index_p = ~Test_index_p;
            Test_data_p =data_inmask_p(Test_index_p,:);Train_data_p =data_inmask_p(Train_index_p,:);
            % controls data
            Test_index_c = (indices_c == i); Train_index_c = ~Test_index_c;
            Test_data_c =data_inmask_c(Test_index_c,:);Train_data_c =data_inmask_c(Train_index_c,:);
            % all data
            Train_data=[Train_data_p;Train_data_c];
            Test_data=[Test_data_p;Test_data_c];
            % all label
            Test_label = [ones(sum(indices_p==i),1);zeros(sum(indices_c==i),1)];
            Train_label =  [ones(sum(indices_p~=i),1);zeros(sum(indices_c~=i),1)];
            % step2�� ��׼�����߹�һ��
            if strcmp(opt.standard,'normalizing')
                MeanValue = mean(Train_data);
                StandardDeviation = std(Train_data);
                [row_quantity, columns_quantity] = size(Train_data);
                Train_data_temp=zeros(row_quantity, columns_quantity);
                for ii = 1:columns_quantity
                    if StandardDeviation(ii)
                        Train_data_temp(:, ii) = (Train_data(:, ii) - MeanValue(ii)) / StandardDeviation(ii);
                    end
                end
                Test_data_temp = (Test_data - MeanValue) ./ StandardDeviation;
                Train_data=Train_data_temp;Test_data=Test_data_temp;
            end
            
            if strcmp(opt.standard,'scale')
                [Train_data_temp,PS] = mapminmax(Train_data');
                Train_data_temp=Train_data_temp';
                Test_data_temp = mapminmax('apply',Test_data',PS);
                Test_data_temp =Test_data_temp';
                Train_data=Train_data_temp;Test_data=Test_data_temp;
            end
            % step3�����뵥��������������
            [~,P,~,~]=ttest2(Train_data(Train_label==1,:), Train_data(Train_label==0,:),'Tail','both');
            Index_ttest2=find(P<=opt.P_threshold);%��С�ڵ���ĳ��Pֵ������ѡ�������
            Train_data= Train_data(:,Index_ttest2);
            Test_data=Test_data(:,Index_ttest2);
            % step4��Feature selection---RFE
            [ feature_ranking_list ] = FeatureSelection_RFE_SVM( Train_data,Train_label,opt );
            % step5�� training model and predict test data using different feature subsets which were selected by step4
            %step4��Feature selection---RFE
            j=0;%������ΪW_M_Brain��ֵ��
            h2 = waitbar(0,'...');
            for FeatureQuantity=opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity %
                w_brain=zeros(1,sum(implicitmask));
                j=j+1;%������
                waitbar(j/Num_FeatureSet,h2,sprintf('%2.0f%%', j/Num_FeatureSet*100)) ;
                Index_selectfeature=feature_ranking_list(1:FeatureQuantity);
                train_data= Train_data(:,Index_selectfeature);
                test_data=Test_data(:,Index_selectfeature);
                label_ForPerformance{i,1}=Test_label;
                % ѵ��ģ��&Ԥ��
                model= fitclinear(train_data,Train_label);
                [predict_label{i,j}, dec_values] = predict(model,test_data);
                Decision{i,j}=dec_values(:,2);
                % estimate mode/SVM
                [accuracy,sensitivity,specificity,ppv,npv]=Calculate_Performances(predict_label{i,j},Test_label);
                Accuracy(i,j) =accuracy;
                Sensitivity(i,j) =sensitivity;
                Specificity(i,j) =specificity;
                PPV(i,j)=ppv;
                NPV(i,j)=npv;
                [AUC(i,j)]=AUC_LC(Test_label,dec_values(:,2));
                %  �ռ��б�ģʽ
                if opt.weight
                    loc_implicitmask=Index_ttest2(Index_selectfeature);
                    w_brain(loc_implicitmask) = reshape(model.Beta,1,numel(model.Beta));
                    W_Brain(j,:,i) = w_brain;%��W_Brian��Index(1:N_feature)����λ�õ�����Ȩ����Ϊ0
                end
                %             if ~randi([0 4])
                %                 parfor_progress;%������
                %             end
            end
            close (h2)
        end
        close (h1)
        %% ==============================================================
    case 0 %equal to leave one out cross validation, LOOCV
        for i=1:opt.K %Outer LOOCV + Inner RFE
            waitbar(i/opt.K,h1,sprintf('%2.0f%%', i/opt.K*100)) ;
            % step1��split data into training data and testing  data
            test_index = (indices == i); train_index = ~test_index;
            Train_data =data_inmask(train_index,:);
            Train_label = label(train_index,:);
            Test_data = data_inmask(test_index,:);
            Test_label = label(test_index);
            label_ForPerformance(i)=Test_label;
            %% step2�� ��׼�����߹�һ��
            if strcmp(opt.standard,'normalizing')
                MeanValue = mean(Train_data);
                StandardDeviation = std(Train_data);
                [row_quantity, columns_quantity] = size(Train_data);
                Train_data_temp=zeros(row_quantity, columns_quantity);
                for ii = 1:columns_quantity
                    if StandardDeviation(ii)
                        Train_data_temp(:, ii) = (Train_data(:, ii) - MeanValue(ii)) / StandardDeviation(ii);
                    end
                end
                Test_data_temp = (Test_data - MeanValue) ./ StandardDeviation;
                Train_data=Train_data_temp;Test_data=Test_data_temp;
            end
            
            if strcmp(opt.standard,'scale')
                [Train_data_temp,PS] = mapminmax(Train_data');
                Train_data_temp=Train_data_temp';
                Test_data_temp = mapminmax('apply',Test_data',PS);
                Test_data_temp =Test_data_temp';
                Train_data=Train_data_temp;Test_data=Test_data_temp;
            end
            %% step3�����뵥��������������
            [~,P,~,~]=ttest2(Train_data(Train_label==1,:), Train_data(Train_label==0,:),'Tail','both');
            Index_ttest2=find(P<=opt.P_threshold);%��С�ڵ���ĳ��Pֵ������ѡ�������
            Train_data= Train_data(:,Index_ttest2);
            Test_data=Test_data(:,Index_ttest2);
            %% step4��Feature selection---RFE
            opt.stepmethod='percentage';opt.step=10;
            [ feature_ranking_list ] = FeatureSelection_RFE_SVM( Train_data,Train_label,opt );
            j=0;%������ΪW_M_Brain��ֵ��
            h2 = waitbar(0,'...');
            for FeatureQuantity=opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity % ��ͬ������Ŀ�����
                w_brain=zeros(1,sum(implicitmask));
                j=j+1;%������
                waitbar(j/Num_FeatureSet,h2,sprintf('%2.0f%%', j/Num_FeatureSet*100));
                Index_selectfeature=feature_ranking_list(1:FeatureQuantity);
                train_data= Train_data(:, Index_selectfeature);
                test_data=Test_data(:, Index_selectfeature);
                % ѵ��ģ��&Ԥ��
                model= fitclinear(train_data,Train_label);
                % Ԥ�� or ����
                [predict_label, dec_values] = predict(model,test_data);
                Decision{i,j}=dec_values(:,2);
                Predict(i,j,1)=predict_label;
                %  �ռ��б�ģʽ
                if opt.weight
                    loc_implicitmask=Index_ttest2(Index_selectfeature);
                    w_brain(loc_implicitmask) = reshape(model.Beta,1,numel(model.Beta));
                    W_Brain(j,:,i) = w_brain;%��W_Brian��Index(1:N_feature)����λ�õ�����Ȩ����Ϊ0
                end
            end
            close (h2)
        end
        close (h1)
end
%% ================���õĴ���==================================
if opt.weight
    %% consensus��ƽ���Ŀռ��б�ģʽ
    binary_mask=W_Brain~=0;
    sum_binary_mask=sum(binary_mask,3);
    loc_consensus=sum_binary_mask>=opt.percentage_consensus*opt.K; num_consensus=sum(loc_consensus,2)';%location and number of consensus weight
    if ~opt.permutation
        disp(['consensus voxel = ' num2str(num_consensus)]);
    end
    W_mean=mean(W_Brain,3);%ȡ����fold�� W_Brain��ƽ��ֵ
    W_mean(~loc_consensus)=0;%set weights located in the no consensus location to zero.
    W_M_Brain(:,implicitmask)=W_mean;%��ͬfeature ��Ŀʱ��ȫ������Ȩ��
end
%% ������������
Accuracy(isnan(Accuracy))=0; Sensitivity(isnan(Sensitivity))=0; Specificity(isnan(Specificity))=0;
PPV(isnan(PPV))=0; NPV(isnan(NPV))=0; AUC(isnan(AUC))=0;
%% ����ģ����opt.K fold�е�ƽ�����ܣ�����LOOCV������
if opt.K<N
    performances=[[mean(Accuracy);mean(Sensitivity);mean(Specificity);mean(PPV);mean(NPV);mean(AUC)],...
        [std(Accuracy);std(Sensitivity);std(Specificity);std(PPV);std(NPV);std(AUC)]];%�ۺϷ�����֣�ǰһ����Mean ��һ����Std
elseif opt.K==N
    [Accuracy, Sensitivity, Specificity, PPV, NPV]=Calculate_Performances(Predict,label_ForPerformance);
    AUC=AUC_LC(label_ForPerformance,cell2mat(Decision));
    performances=[Accuracy, Sensitivity, Specificity, PPV, NPV,AUC]';%�ۺϷ������
end
%% identify the best performance���Լ�����Ӧ��������������consensus������������ȷ����Ӧ��weight��num_consensus
%��AUCΪ��׼�ҵ���õ�AUC����λ�ã����ҵ���õķ�������Լ����AUC��Ӧ��weight
N_plot=length(opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity);
meanAUC=performances(6,(1:1:N_plot)); meanaccuracy=performances(1,(1:1:N_plot));
meansensitivity=performances(2,(1:1:N_plot));meanspecificity=performances(3,(1:1:N_plot));
loc_best_meanaccuracy=find(meanaccuracy==max(meanaccuracy));%�ο���������:Accuracy
loc_best_meanaccuracy=loc_best_meanaccuracy(1);
AUC_best=meanAUC(loc_best_meanaccuracy);Accuracy_best=meanaccuracy(loc_best_meanaccuracy);
%for permutation test
Sensitivity_best=meansensitivity(loc_best_meanaccuracy); Specificity_best=meanspecificity(loc_best_meanaccuracy);
predict_label_best=predict_label(:,loc_best_meanaccuracy);
predict_label_best=cell2mat(predict_label_best);
if ~opt.permutation
    disp(['best AUC,Accuracy,Sensitivity and Specificity = '...
        ,num2str([AUC_best,Accuracy_best,Sensitivity_best,Specificity_best])]);
end
%��Ӧ������������consensus������
if opt.weight
    NumBestConsensusFeature=num_consensus(loc_best_meanaccuracy);
    AllFeatureSubset=(opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity);
    NumBestFeature=AllFeatureSubset(loc_best_meanaccuracy);
    W_M_Brain_best=W_M_Brain(loc_best_meanaccuracy,:);
    W_M_Brain_3D=reshape(W_M_Brain_best,dim1,dim2,dim3);%best W_M_Brain_3D
    if ~opt.permutation
        disp(['NumBestConsensusFeature and NumBestFeature = ' num2str(NumBestConsensusFeature),' and ', num2str(NumBestFeature),' respectively']);
    end
end
%% visualize performance
if opt.viewperformance
    % Name_plot={'accuracy','sensitivity', 'specificity', 'PPV', 'NPV','AUC'};
    N_plot=length(opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity);
    figure;
    plot((opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity),performances(1,(1:1:N_plot)),...
        '-','markersize',5,'LineWidth',2);title('Mean accuracy');
    figure;
    plot((opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity),performances(2,(1:1:N_plot)),...
        '-','markersize',5,'LineWidth',2);title('Mean sensitivity');
    figure;
    plot((opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity),performances(3,(1:1:N_plot)),...
        '-','markersize',5,'LineWidth',2);title('Mean specificity');
    figure;
    plot((opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity),performances(6,(1:1:N_plot)),...
        '-','markersize',5,'LineWidth',2); title('Mean AUC');
    % error bar of Accuracy
    figure;
    %      errorbar(mean(Accuracy),std(Accuracy));
    dy=std(Accuracy);
    MeanAccurcay=mean(Accuracy);
    loc_maxAccuracy=find(mean(Accuracy)==max(mean(Accuracy)));
    loc_maxAccuracy= loc_maxAccuracy(1);
    maxAccuracy= MeanAccurcay(loc_maxAccuracy);
    axis_x=1:size(Accuracy,2);
    %      axis_x=opt.Initial_FeatureQuantity:opt.Step_FeatureQuantity:opt.Max_FeatureQuantity;
    fig_fill=fill([axis_x,fliplr(axis_x)],[MeanAccurcay-dy,fliplr(MeanAccurcay+dy)],[0.5 0.2 0.2]);%���CI
    fig_fill.EdgeColor=[0.8 0.2 0.2];fig_fill.FaceColor='r';fig_fill.LineStyle='none';
    fig_fill.FaceAlpha=0.3;
    hold on;
    line([loc_maxAccuracy,loc_maxAccuracy],[maxAccuracy-dy(loc_maxAccuracy),maxAccuracy+dy(loc_maxAccuracy)],'Color',[1 0 0],'LineWidth',2);
    plot(loc_maxAccuracy,maxAccuracy,'o','MarkerSize',8,'Color',[1 0 0],'LineWidth',2)
    plot(axis_x,MeanAccurcay,'-','MarkerSize',8,'Color',[0.6 0 0],'LineWidth',1)
end
%% ������ѵķ���Ȩ��ͼ��������
Time=datestr(now,30);
if opt.saveresults
    %��Ž��·��
    loc= find(path=='\');
    outdir=path(1:loc(length(find(path=='\'))-2)-1);%path����һ��Ŀ¼
    %gray matter masopt.K
    if opt.weight
        [file_name,path_source1,~]= uigetfile( ...
            {'*.img;*.nii;','All Image Files';...
            '*.*','All Files' },...
            '��ѡ��mask����ѡ��', ...
            'MultiSelect', 'off');
        img_strut_temp=load_nii([path_source1,char(file_name)]);
        mask_graymatter=img_strut_temp.img~=0;
        W_M_Brain_3D(~mask_graymatter)=0;
        % save nii
        cd (outdir)
        Data2Img_LC(W_M_Brain_3D,['W_M_Brain_3D_',Time,'.nii']);
    end
    % ������������ȷ����Щ���Եķ���Ч������
    label_ForPerformance= cell2mat( label_ForPerformance);
    predict_label=cell2mat(predict_label);
    loc_badsubjects=(label_ForPerformance-predict_label_best)~=0;
    name_badsubjects=name_all_sorted(loc_badsubjects);
    save([outdir filesep [Time,'Results_MVPA.mat']],...
        'Accuracy', 'Sensitivity', 'Specificity','PPV', 'NPV', 'Decision', 'AUC',...
        'label_ForPerformance','predict_label_best','name_badsubjects',...
        'AUC_best','Accuracy_best','Sensitivity_best','Specificity_best',...
        'indices','indices_p','indices_c');
end
end
