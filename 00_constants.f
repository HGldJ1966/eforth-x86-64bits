
: // 10 parse 2drop ; immediate   // �� 13 �|�����D�A�᭱���� 13 10 �����η|�Y���U�@��I�� 10 �N�n�F�C

' // '\ !  \ �� back slash ���w�q�����A�_�h�ӭ쪩 \ �@�X�{�N���� including source.

// ���� display ��X�ɦV�@�� memory �H�K�ݱo�� error message.

\   auxtx!         ( c -- )
\                  putchar to stdout.
\                  This is an auxiliary to be used before real word will be ready.

                   \ eforth64.asm R18 ����w�g�b cold ���e���h map �� 2M new page space $200000~$3fffff
                   \ ���䤤 $300000 ���᪺�a��ө� console ready ���e�� message. �� bochsdbg.exe �N�i�H
                   \ ���P�ݨ��C

                   create auxposition $300000 ,

                   : auxtx!  ( c -- )
                     auxposition @ c!
                     auxposition @ 1+ auxposition !
                   ;

                   ' auxtx! 'emit !   \ �I��

\   .s(debug)      ( ... -- ... )
\                  Display the contents of the data stack. ²�K���� .s debug ���W�n�ΤF�C
                   
                   : .s(debug)
                       cr depth                      \ stack depth
                       for aft                       \ start count down loop, skip first pass
                         r@ pick .                   \ index stack, display contents
                       then next                     \ loop till done
                       ."  <sp " 
                   ;

.(  including 00_constants.f ) cr

// �t�α`��         constant �٥��X�{���e���o�˥ΡA�S���򤣦n�C

: revision 560026 ; \ �� tiny assembler - disassembler
: HIDE  $20 ;  \ lexicon hidden bit   Hide-Reveal is important for code end-code words
: COMPO $40 ;  \ lexicon compile only bit
: IMEDD $80 ;  \ lexicon immediate bit
: CALLL $E8 ;  \ call's op-code
: JMPP  $E9 ;  \ jmp.r32 op-code
: RETT  $C3 ;  \ ret op-code

// Debugger switchs

create int3mode  0 ,  \ 1=���b int3 mode ��, 0=���} int3 mode, 2=���� int3 mode �\��.
create debugmode 0 ,  \ 1=���b debug mode ��, 0=���} debug mode, 2=���� debug mode �\��.
create pausemode 1 ,  \ 1=���`�ϥ� pause mode, 0=���� pause mode �\��.


