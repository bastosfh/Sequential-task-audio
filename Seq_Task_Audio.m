cd '/home/coleta/Seq_Task_Audio';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% inicio das configuracoes%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grupo = 'teste_ricardo';
% Nome do grupo que irá coletar (entre aspas simples);
% Este nome sera utilizado para formar o nome do arquivo
% Caso seja um grupo yoked, coloque o nome do grupo a ser espelhado (autocontrolado)

sjnum = '1';
% Número do sujeito

autocontrolado = '1';
% Especifica se o grupo é autocontrolado (1), yoked (2)
% No caso de yoked, o grupo e número de sj indicados serão utilizados

sq_definida = '1';
% sq_definida = '1'; Se autocontrolado = '1', a sequência é livre; Se autocontrolado = '2', lê a sq do sj autocontrolado
% sq_definida = '2'; Mantém nome do grupo, sjnum e condição; utiliza o sequenciamento definido no arquivo 'seq_adapt.txt';
% sq_definida = '3'; Mantém nome do grupo, sjnum e condição; exibe a sequência somente nas posições 2, 4 e 6 (definida em 'seq_adapt.txt');
% sq_definida = '4'; Mantém nome do grupo, sjnum e condição; exibe a sequência somente nas posições 2, 4 e 6 (definida em 'seq_adapt.txt'); O beep é apresentado no componente inicial e final

ntt = 3;
% Número de tentativas de pratica

feedback = '1';
% Feedback = 1 (grupo recebe feedback apos a pratica);
% Feedback = 2 (grupo nao recebe feedback)

starting_point = '1';
% 1 = à esquerda dos alvos
% 2 = à direita dos alvos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Somente modifique abaixo se souber o que está fazendo %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arquivo_audio = 'wait_audio.txt';
% Nome do arquivo contendo os intervalos entre beeps

arquivo_sq_adaptacao = 'seq_adapt.txt';
% Nome do arquivo contendo a sequencia a ser utilizada na adaptacao

vertical_increment = 0;
% Modifica a posição dos alvos na tela, aproximando ou afastando-os verticalmente;
% vertical_increment = 0: mantem os alvos na posicao "original";
% vertical_increment = 50: afasta os alvos verticalmente 100 pixels;
% Obs: vertical_increment pode ser ajustado para qualquer valor
% (a relacao pixel x distancia varia conforme a resolucao do monitor)

mostrar_num_yoked = '1';
% mostrar_num_yoked = '1'; a sequencia é apresentada
% mostrar_num_yoked = '2'; a sequencia não é apresentada

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% fim das configuracoes%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

txt_name = sprintf('%s_suj%s.txt', grupo, sjnum); %  Nome do arquivo txt para salvar todas as tentativas do sujeito

% Endereco em que foi colocado o script
script_path = ('/home/coleta/Seq_Task_Audio');


% Verifica a fase primeiro, antes de ver se é auto ou yoked
if sq_definida == '1'
    
    if autocontrolado == '1'
        sj_path = sprintf('/home/coleta/Seq_Task_Audio/%s_suj%s', grupo, sjnum);
    elseif autocontrolado == '2'
        % Caso seja especificado ao programa que a coleta será de um yoked, este é o endereco:
        sj_path = sprintf('/home/coleta/Seq_Task_Audio/yoked_%s_suj%s', grupo, sjnum);
        yok_path = sprintf('/home/coleta/Seq_Task_Audio/%s_suj%s/%s_suj%s.txt', grupo, sjnum, grupo, sjnum);
        yok_file = dlmread(yok_path); % Lê o arquivo do sj autocontrolado
        txt_name = sprintf('yoked_%s_suj%s.txt', grupo, sjnum); %  Nome do arquivo txt para salvar todas as tentativas do sujeito
    end
    
elseif sq_definida == '2' || sq_definida == '3' || sq_definida == '4'
    
    if autocontrolado == '1'
        sj_path = sprintf('/home/coleta/Seq_Task_Audio/%s_suj%s', grupo, sjnum);
        yok_path = sprintf('/home/coleta/Seq_Task_Audio/%s', arquivo_sq_adaptacao);
        yok_file = dlmread(yok_path); % Lê o arquivo fixo (adaptação) ao invés de ler o yoked
        autocontrolado = '2'; % Para que as funções (animação) se comportem como se o yoked tivesse sido selecionado
    elseif autocontrolado == '2'
        sj_path = sprintf('/home/coleta/Seq_Task_Audio/yoked_%s_suj%s', grupo, sjnum);
        yok_path = sprintf('/home/coleta/Seq_Task_Audio/%s', arquivo_sq_adaptacao);
        yok_file = dlmread(yok_path); % Lê o arquivo fixo (adaptação) ao invés de ler o yoked
        txt_name = sprintf('yoked_%s_suj%s.txt', grupo, sjnum); %  Nome do arquivo txt para salvar todas as tentativas do sujeito
    end
    
end

% Faz uma pasta para armazenar as tentativas do sujeito
mkdir(sj_path);

% Lê o arquivo com o intervalo entre estímulos auditivos
wait_audio = dlmread(sprintf('/home/coleta/Seq_Task_Audio/%s', arquivo_audio));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

screenNum = 0;

% Opens the active window
[wPtr,rect] = Screen('OpenWindow', screenNum); %  Using screen number only, the whole screen is used as default

% Color parameters MUST came after openning the window
black = BlackIndex(wPtr);
white = WhiteIndex(wPtr);
red = [255 0 0];
green = [0 255 0];

% Fills the open window with black
Screen('FillRect',wPtr,black);
Screen('Flip', wPtr); %  Flip
HideCursor;
WaitSecs(0.5); %  Waits a specified time (in seconds)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Audio Config %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize driver, request low-latency preinit:
InitializePsychSound(1);

if ~IsLinux
    PsychPortAudio('Verbosity', 10);
end

% Necessario consultar usando PsychPortAudio('GetDevices').
% Entretanto, -1 parece indicar o Low Latency Output Device
deviceid = -1;

% Request latency mode 2, which used to be the best one in our measurement:
% classes 3 and 4 didn't yield any improvements, sometimes they even caused
% problems.
reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2

% Requested output frequency, may need adaptation on some audio-hw:
freq = 44100;       % Must set this. 96khz, 48khz, 44.1khz.
buffersize = 0;     % Pointless to set this. Auto-selected to be optimal.
suggestedLatencySecs = [];

% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);

% Generate some beep sound 1000 Hz, 0.1 secs, 90% amplitude:
mynoise(1,:) = 0.5 * MakeBeep(1000, 0.1, freq);
mynoise(2,:) = mynoise(1,:);

PsychPortAudio('FillBuffer', pahandle, mynoise);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Adquire a frequencia do monitor para calcular o tempo entre os estimulos auditivos
[ monitorFlipInterval nrValidSamples stddev ] = Screen('GetFlipInterval', wPtr);
% Put functions into memory for speed
GetSecs;
WaitSecs(0.1);

%%%%%%%%%%%%%%%%%%%%%%%%
% Loop de tentativas
for i = 1:ntt
    
    trial = i;
    
    % Sets cursor starting position to the center of the open window
    x_mouse_ini = 50; %rect(RectRight)/2;
    y_mouse_ini = rect(RectBottom)/2;
    SetMouse(x_mouse_ini, y_mouse_ini);
    
    WaitSecs(0.5); %  Espera o cursor ser posicionado
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('TextFont',wPtr, 'Ubuntu');
    % Escreve o texto para o início da tentativa
    % e registra o tempo utilizado para que o sj a inicie
    texto_tela_ini = sprintf('Pressione qualquer tecla para a tentativa %s de %s',...
        num2str(trial), num2str(ntt));
    
    Screen('TextSize',wPtr, 40);
    Screen('DrawText', wPtr, texto_tela_ini, 500, 500, [255, 255, 255]);
    
    if autocontrolado == '1'
        Screen('TextSize',wPtr, 30);
        Screen('DrawText', wPtr, 'Você pode tocar nos retângulos na ordem que preferir', 500, 800, green);
    end
    
    Screen('Flip', wPtr);
    
    time_ini = GetSecs; %  Inicia o cronometro
    keyIsDown = 0;
    while keyIsDown == 0
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        time_end = GetSecs; %  Fecha o cronometro
    end
    time_to_hit_enter = time_end - time_ini;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% animação principal %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sets cursor starting position, based on the starting_point value
    if starting_point == '1'
        x_mouse_ini = round(rect(RectRight)/35);
        y_mouse_ini = rect(RectBottom)/2 - round((rect(RectRight)/35)/2);
        SetMouse(x_mouse_ini, y_mouse_ini);
    elseif starting_point == '2'
        x_mouse_ini = rect(RectRight) - round(rect(RectRight)/18.2);
        y_mouse_ini = rect(RectBottom)/2 - round((rect(RectRight)/35)/2);
        SetMouse(x_mouse_ini, y_mouse_ini);
    end
    
    % Fills the open window with black
    Screen('FillRect',wPtr,black);
    Screen('Flip', wPtr); %flip
    HideCursor;
    WaitSecs(1); %  Waits a specified time (in seconds)
    
    %%%%%%%%%%%%%%%%%%%%%%%% alvos e cursores para a pratica %%%%%%%%%%%%%%%%%%%%%%%%
    % Target size
    size_horiz = rect(RectRight)/11;
    size_vert = rect(RectRight)/45;
    
    % Cursor size
    cursor_horiz = rect(RectRight)/35;
    cursor_vert = cursor_horiz;
    
    % Distance between cursors
    cursor_dist_h = rect(RectRight)/4 + (cursor_horiz/2);
    cursor_dist_v = ((y_mouse_ini - rect(RectBottom)/5)*2) + size_vert;
    
    % Cursor case size
    case_h = cursor_horiz*0.7;
    case_v = case_h;
    
    % Target 1 coordinates
    x_esq1 = rect(RectRight)/5 - (cursor_horiz/2);
    x_dir1 = x_esq1 + size_horiz;
    y_esq1 = rect(RectBottom)/5 - vertical_increment;
    y_dir1 = y_esq1 + size_vert;
    
    % Target 2 coordinates
    x_esq2 = rect(RectRight)/5 - (cursor_horiz/2) + cursor_dist_h;
    x_dir2 = x_esq2 + size_horiz;
    y_esq2 = rect(RectBottom)/5 - vertical_increment;
    y_dir2 = y_esq2 + size_vert;
    
    % Target 3 coordinates
    x_esq3 = rect(RectRight)/5 - (cursor_horiz/2) + cursor_dist_h*2;
    x_dir3 = x_esq3 + size_horiz;
    y_esq3 = rect(RectBottom)/5 - vertical_increment;
    y_dir3 = y_esq3 + size_vert;
    
    % Target 4 coordinates
    x_esq4 = rect(RectRight)/5 - (cursor_horiz/2);
    x_dir4 = x_esq4 + size_horiz;
    y_esq4 = rect(RectBottom)/5 + cursor_dist_v + vertical_increment;
    y_dir4 = y_esq4 + size_vert;
    
    % Target 5 coordinates
    x_esq5 = rect(RectRight)/5 - (cursor_horiz/2) + cursor_dist_h;
    x_dir5 = x_esq5 + size_horiz;
    y_esq5 = rect(RectBottom)/5 + cursor_dist_v + vertical_increment;
    y_dir5 = y_esq5 + size_vert;
    
    % Target 6 coordinates
    x_esq6 = rect(RectRight)/5 - (cursor_horiz/2) + cursor_dist_h*2;
    x_dir6 = x_esq6 + size_horiz;
    y_esq6 = rect(RectBottom)/5 + cursor_dist_v + vertical_increment;
    y_dir6 = y_esq6 + size_vert;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Coordenadas para exibir o feedback
    x_feed1 = x_esq1;
    y_feed1 = y_esq1;
    
    x_feed2 = x_esq2;
    y_feed2 = y_esq2;
    
    x_feed3 = x_esq3;
    y_feed3 = y_esq3;
    
    x_feed4 = x_esq4;
    y_feed4 = y_esq4;
    
    x_feed5 = x_esq5;
    y_feed5 = y_esq5;
    
    x_feed6 = x_esq6;
    y_feed6 = y_esq6;
    
    % Pool with all positions for feedback drawing
    x_feed_all = [x_feed1 x_feed2 x_feed3 x_feed4 x_feed5 x_feed6];
    y_feed_all = [y_feed1 y_feed2 y_feed3 y_feed4 y_feed5 y_feed6];
    
    % Loop variables (prealocating for speed)
    time_ini = [];
    time_target1 = [];
    time_target2 = [];
    time_target3 = [];
    time_target4 = [];
    time_target5 = [];
    time_target6 = [];
    
    sequence = [];
    sequence_all = [];
    
    % Variaveis do loop relacionadas ao audio
    audio_timer1 = 0;
    audio_timer2 = 0;
    audio_timer3 = 0;
    audio_timer4 = 0;
    audio_timer5 = 0;
    audio_timer6 = 0;
    
    audio1_on = 0;
    audio2_on = 0;
    audio3_on = 0;
    audio4_on = 0;
    audio5_on = 0;
    audio6_on = 0;
    
    time_audio1 = [];
    time_audio2 = [];
    time_audio3 = [];
    time_audio4 = [];
    time_audio5 = [];
    time_audio6 = [];
    
    %  Determina o tempo para cada estimulo auditivo, em segundos (s)
    wait_audio1 = wait_audio(1);
    wait_audio2 = wait_audio(2);
    wait_audio3 = wait_audio(3);
    wait_audio4 = wait_audio(4);
    wait_audio5 = wait_audio(5);
    wait_audio6 = wait_audio(6);
    
    % Dummy para armazenar posições do mouse para a demonstração
    x_mouse_all = [];
    y_mouse_all = [];
    
    % Start the playback engine with an infinite start deadline, ie.,
    % start hardware, but don't play sound:
    PsychPortAudio('Start', pahandle, 1, inf, 0);
    time_before_loop = GetSecs; % Para calcular o tempo em que o cursor fica no ponto inicial
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% while loop da animação %%%%%%%%%%%%%%%%%%%%
    while (length(sequence_all)) < 6
        
        audio_timer1 = audio_timer1 + audio1_on; %  Timer to trigger audio events
        audio_timer2 = audio_timer2 + audio2_on; %  Timer to trigger audio events
        audio_timer3 = audio_timer3 + audio3_on; %  Timer to trigger audio events
        audio_timer4 = audio_timer4 + audio4_on; %  Timer to trigger audio events
        audio_timer5 = audio_timer5 + audio5_on; %  Timer to trigger audio events
        audio_timer6 = audio_timer6 + audio6_on; %  Timer to trigger audio events
        
        
        %%%%%%%%%%%%% Draws targets
        % Draws targets
        Screen('FillRect', wPtr, red, [x_esq1 y_esq1 x_dir1 y_dir1]);
        Screen('FillRect', wPtr, red, [x_esq2 y_esq2 x_dir2 y_dir2]);
        Screen('FillRect', wPtr, red, [x_esq3 y_esq3 x_dir3 y_dir3]);
        Screen('FillRect', wPtr, red, [x_esq4 y_esq4 x_dir4 y_dir4]);
        Screen('FillRect', wPtr, red, [x_esq5 y_esq5 x_dir5 y_dir5]);
        Screen('FillRect', wPtr, red, [x_esq6 y_esq6 x_dir6 y_dir6]);
        
        
        % Draws the cursor case
        % Screen('DrawLine', windowPtr [,color], fromH, fromV, toH, toV [,penWidth]);
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini-case_v, x_mouse_ini+case_h+cursor_horiz, y_mouse_ini-case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini+cursor_horiz+case_h, y_mouse_ini-case_v, x_mouse_ini+cursor_horiz+case_h, y_mouse_ini+cursor_vert+case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini+cursor_vert+case_v, x_mouse_ini+case_h+cursor_horiz, y_mouse_ini+cursor_vert+case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini-case_v, x_mouse_ini-case_h, y_mouse_ini+cursor_vert+case_v, 1);
        
        
        % Draws mouse cursor
        [x_mouse,y_mouse,buttons] = GetMouse(wPtr);
        Screen('FillRect', wPtr, red, [x_mouse y_mouse (x_mouse + cursor_horiz) (y_mouse + cursor_vert)]);
        
        % Draws the sequence used by self-controlled
        if autocontrolado == '2' && mostrar_num_yoked == '1' && sq_definida != '3' && sq_definida != '4'
            Screen('DrawText', wPtr, '1', (x_feed_all(yok_file(trial, 7)) + size_horiz/2), y_feed_all(yok_file(trial, 7)), black);
            Screen('DrawText', wPtr, '2', (x_feed_all(yok_file(trial, 8)) + size_horiz/2), y_feed_all(yok_file(trial, 8)), black);
            Screen('DrawText', wPtr, '3', (x_feed_all(yok_file(trial, 9)) + size_horiz/2), y_feed_all(yok_file(trial, 9)), black);
            Screen('DrawText', wPtr, '4', (x_feed_all(yok_file(trial, 10)) + size_horiz/2), y_feed_all(yok_file(trial, 10)), black);
            Screen('DrawText', wPtr, '5', (x_feed_all(yok_file(trial, 11)) + size_horiz/2), y_feed_all(yok_file(trial, 11)), black);
            Screen('DrawText', wPtr, '6', (x_feed_all(yok_file(trial, 12)) + size_horiz/2), y_feed_all(yok_file(trial, 12)), black);
        end
        
        % Exibe somente os elementos 2, 4 e 6 da sq (caso sq_definida seja igual a 3 - configurações)
        if sq_definida == '3' || sq_definida == '4'
            Screen('DrawText', wPtr, (num2str(yok_file(trial, 8))), (x_feed2 + size_horiz/2), y_feed2, black);
            Screen('DrawText', wPtr, (num2str(yok_file(trial, 10))), (x_feed4 + size_horiz/2), y_feed4, black);
            Screen('DrawText', wPtr, (num2str(yok_file(trial, 12))), (x_feed6 + size_horiz/2), y_feed6, black);
        end
        
        % Time when the cursor was first moved
        if starting_point == '1'
            
            if (((x_mouse_ini + cursor_horiz + case_h) - (x_mouse + cursor_horiz)) < 0) | ((y_mouse - (y_mouse_ini - case_v)) < 0) |...
                    ((y_mouse_ini + cursor_vert + case_v) - (y_mouse + cursor_vert) < 0) | (x_mouse - (x_mouse_ini - case_h) < 0)
                
                if length(time_ini) < 1
                    time_ini = GetSecs;
                    % PsychPortAudio('RescheduleStart', pahandle, 0, 0); %  beeps when the cursor gets out
                    audio1_on = monitorFlipInterval; %  start counting the time to the first beep
                end
            end
            
        elseif starting_point == '2'
            
            if (x_mouse - (x_mouse_ini - case_h) < 0) | ((y_mouse - (y_mouse_ini - case_v)) < 0) | ((y_mouse_ini + cursor_vert + case_v) - (y_mouse + cursor_vert) < 0) |...
                    (x_mouse_ini + cursor_horiz + case_h) - (x_mouse + cursor_horiz) < 0
                
                if length(time_ini) < 1
                    time_ini = GetSecs;
                    % PsychPortAudio('RescheduleStart', pahandle, 0, 0); %  beeps when the cursor gets out
                    audio1_on = monitorFlipInterval; %  start counting the time to the first beep
                end
            end
        end
        
        % Os beeps não são apresentados caso sq_definida = '4' (configurações)
        if sq_definida != '4'
            % Audio events
            if audio_timer1 > wait_audio1 && length(time_audio1) < 1
                time_audio1 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio2_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer2 > wait_audio2 && length(time_audio2) < 1
                time_audio2 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio3_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer3 > wait_audio3 && length(time_audio3) < 1
                time_audio3 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio4_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer4 > wait_audio4 && length(time_audio4) < 1
                time_audio4 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio5_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer5 > wait_audio5 && length(time_audio5) < 1
                time_audio5 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio6_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer6 > wait_audio6 && length(time_audio6) < 1
                time_audio6 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
            end
        end
        
        % Os beeps não são apresentados caso sq_definida = '4' (configurações)
        if sq_definida == '4'
            % Audio events
            if audio_timer1 > wait_audio1 && length(time_audio1) < 1
                time_audio1 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio2_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer2 > wait_audio2 && length(time_audio2) < 1
                time_audio2 = GetSecs;
                %PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio3_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer3 > wait_audio3 && length(time_audio3) < 1
                time_audio3 = GetSecs;
                %PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio4_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer4 > wait_audio4 && length(time_audio4) < 1
                time_audio4 = GetSecs;
                %PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio5_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer5 > wait_audio5 && length(time_audio5) < 1
                time_audio5 = GetSecs;
                %PsychPortAudio('RescheduleStart', pahandle, 0, 0);
                audio6_on = monitorFlipInterval; %  start counting the time to the other beeps
            end
            
            if audio_timer6 > wait_audio6 && length(time_audio6) < 1
                time_audio6 = GetSecs;
                PsychPortAudio('RescheduleStart', pahandle, 0, 0);
            end
        end
        
        %conditions for targets to disappear
        %kills target 1
        if ((x_esq1 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir1) < 0) && (y_esq1 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir1 < 0))
            x_esq1 = 0;
            x_dir1 = 0;
            y_esq1 = 0;
            y_dir1 = 0;
            
            time_target1 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 1];
        end
        
        %kills target 2
        if ((x_esq2 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir2) < 0) && (y_esq2 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir2 < 0))
            x_esq2 = 0;
            x_dir2 = 0;
            y_esq2 = 0;
            y_dir2 = 0;
            
            time_target2 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 2];
        end
        
        %kills target 3
        if ((x_esq3 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir3) < 0) && (y_esq3 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir3 < 0))
            x_esq3 = 0;
            x_dir3 = 0;
            y_esq3 = 0;
            y_dir3 = 0;
            
            time_target3 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 3];
        end
        
        %kills target 4
        if ((x_esq4 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir4) < 0) && (y_esq4 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir4 < 0))
            x_esq4 = 0;
            x_dir4 = 0;
            y_esq4 = 0;
            y_dir4 = 0;
            
            time_target4 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 4];
        end
        
        %kills target 5
        if ((x_esq5 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir5) < 0) && (y_esq5 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir5 < 0))
            x_esq5 = 0;
            x_dir5 = 0;
            y_esq5 = 0;
            y_dir5 = 0;
            
            time_target5 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 5];
        end
        
        %kills target 6
        if ((x_esq6 - (x_mouse + cursor_horiz)) < 0 && ((x_mouse - x_dir6) < 0) && (y_esq6 - (y_mouse + cursor_vert)) < 0 && (y_mouse - y_dir6 < 0))
            x_esq6 = 0;
            x_dir6 = 0;
            y_esq6 = 0;
            y_dir6 = 0;
            
            time_target6 = GetSecs; %gets the time (in the frame) in which target1 was killed
            sequence = [sequence 6];
        end
        
        if length(time_audio6) != 0
            sequence_all = sequence;
        end
        
        %armazenar as posições do mouse para a demontração
        x_mouse_all = [x_mouse_all; x_mouse];
        y_mouse_all = [y_mouse_all; y_mouse];
        
        Screen('Flip', wPtr);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    Screen('Flip', wPtr);
    WaitSecs(0.1);
    
    time_cursor_first_move = time_ini - time_before_loop;
    
    % Stop playback:
    PsychPortAudio('Stop', pahandle, 1);
    
    
    % Calculo dos tempos parciais
    
    time_all = [time_target1 time_target2 time_target3 time_target4 time_target5 time_target6];
    
    time_first_component = time_all(sequence(1)) - time_ini(1); % Calculates the time between start moving and the first hit target
    time_second_component = time_all(sequence(2)) - time_all(sequence(1)); % Calculates the time between first and second hit targets
    time_third_component = time_all(sequence(3)) - time_all(sequence(2)); % Calculates the time between second and third hit targets
    time_fourth_component = time_all(sequence(4)) - time_all(sequence(3));
    time_fifth_component = time_all(sequence(5)) - time_all(sequence(4));
    time_sixth_component = time_all(sequence(6)) - time_all(sequence(5));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculo do feedback
    
    % Garante que haverá feedback mesmo que os dois últimos beeps não ocorrão
    % (caso o sj antecipe demais os toques)
    %if length(time_audio6) == 0 && length(time_audio5) == 0
    %time_audio5 = time_audio4 + wait_audio5;
    %time_audio6 = time_audio5 + wait_audio6;
    %elseif length(time_audio6) == 0
    %time_audio6 = time_audio5 + wait_audio6;
    %end
    
    model_times = [time_audio1 time_audio2 time_audio3 time_audio4 time_audio5 time_audio6];
    
    first_component_feedback = num2str(round((time_all(sequence(1)) - time_audio1)*1000));
    second_component_feedback = num2str(round((time_all(sequence(2)) - time_audio2)*1000));
    third_component_feedback = num2str(round((time_all(sequence(3)) - time_audio3)*1000));
    fourth_component_feedback = num2str(round((time_all(sequence(4)) - time_audio4)*1000));
    fifth_component_feedback = num2str(round((time_all(sequence(5)) - time_audio5)*1000));
    sixth_component_feedback = num2str(round((time_all(sequence(6)) - time_audio6)*1000));
    
    first_component_timing = time_all(sequence(1)) - time_audio1;
    second_component_timing = time_all(sequence(2)) - time_audio2;
    third_component_timing = time_all(sequence(3)) - time_audio3;
    fourth_component_timing = time_all(sequence(4)) - time_audio4;
    fifth_component_timing = time_all(sequence(5)) - time_audio5;
    sixth_component_timing = time_all(sequence(6)) - time_audio6;
    
    %% Pool with all positions for feedback drawing
    x_feed_all = [x_feed1 x_feed2 x_feed3 x_feed4 x_feed5 x_feed6];
    y_feed_all = [y_feed1 y_feed2 y_feed3 y_feed4 y_feed5 y_feed6];
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Draws the feedback
    
    if feedback == '1' && sq_definida != '3' && sq_definida != '4'
        
        Screen('TextSize',wPtr, 40);
        
        %feedback for the first target hit
        Screen('DrawText', wPtr, first_component_feedback, x_feed_all(sequence(1)), y_feed_all(sequence(1)), [255, 0, 0]);
        Screen('DrawText', wPtr, second_component_feedback, x_feed_all(sequence(2)), y_feed_all(sequence(2)), [255, 0, 0]);
        Screen('DrawText', wPtr, third_component_feedback, x_feed_all(sequence(3)), y_feed_all(sequence(3)), [255, 0, 0]);
        Screen('DrawText', wPtr, fourth_component_feedback, x_feed_all(sequence(4)), y_feed_all(sequence(4)), [255, 0, 0]);
        Screen('DrawText', wPtr, fifth_component_feedback, x_feed_all(sequence(5)), y_feed_all(sequence(5)), [255, 0, 0]);
        Screen('DrawText', wPtr, sixth_component_feedback, x_feed_all(sequence(6)), y_feed_all(sequence(6)), [255, 0, 0]);
        
        %draws the cursor case
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini-case_v, x_mouse_ini+case_h+cursor_horiz, y_mouse_ini-case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini+cursor_horiz+case_h, y_mouse_ini-case_v, x_mouse_ini+cursor_horiz+case_h, y_mouse_ini+cursor_vert+case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini+cursor_vert+case_v, x_mouse_ini+case_h+cursor_horiz, y_mouse_ini+cursor_vert+case_v, 1);
        Screen('DrawLine', wPtr, red, x_mouse_ini-case_h, y_mouse_ini-case_v, x_mouse_ini-case_h, y_mouse_ini+cursor_vert+case_v, 1);
        
        
        if autocontrolado == '2'
            
            if yok_file(trial, 7) != sequence(1) | yok_file(trial, 8) != sequence(2) | yok_file(trial, 9) != sequence(3) |...
                    yok_file(trial, 10) != sequence(4) | yok_file(trial, 11) != sequence(5) | yok_file(trial, 12) != sequence(6)
                
                Screen('DrawText', wPtr, 'Sequência incorreta!', rect(RectRight)/2.5, rect(RectBottom)/2, white);
                
            end
            
        end
        
        Screen('Flip', wPtr);
        
        % Mede o tempo em que o sujeito passou olhando o feedback
        time_feedback_ini = GetSecs;
        [time_feedback_end, keyCode, deltaSecs] = KbWait;
        time_feedback = time_feedback_end - time_feedback_ini;
        
    else
        
        time_feedback = 0;
        Screen('Flip', wPtr);
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Salva arquivo com os dados do sujeito
    
    cd(sj_path); %entra na pasta do sujeito para salvar o arquivo
    
    dados_tentativa = [time_first_component time_second_component time_third_component time_fourth_component...
        time_fifth_component time_sixth_component sequence wait_audio first_component_timing second_component_timing...
        third_component_timing fourth_component_timing fifth_component_timing sixth_component_timing...
        time_to_hit_enter time_cursor_first_move time_feedback];
    
    dlmwrite(txt_name, dados_tentativa, 'delimiter', '\t', '-append');
    
    
    %salva arquivo com as posições xy praticadas
    mouse_all = [x_mouse_all y_mouse_all];
    txt_name_mouse_pos = sprintf('%s_feed%s_suj%s_trajetorias_tt%s.txt',...
        grupo, feedback, sjnum, num2str(trial)); %nome do arquivo txt para salvar todas as tentativas do sujeito
    
    dlmwrite(txt_name_mouse_pos, mouse_all, 'delimiter', '\t') %, '-append');
    
    cd(script_path); %volta para a pasta onde esta o script
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% agradecimento %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (trial - ntt) == 0
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'OBRIGADO!', 300, 300, [255, 255, 255]);
        Screen('Flip', wPtr);
        WaitSecs(0.2);
        [end_experiment_time, keyCode, deltaSecs] = KbWait; %aguarda o enter para encerrar o experimento
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% fecha o loop de tentativas %%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% Set priority to normal level
ShowCursor;
Priority(0);
PsychPortAudio('Close');
Screen('CloseAll');

