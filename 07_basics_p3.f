
.(  including 07_basics_p3.f ) cr

console definitions

// Basics part III
// These words rely on the readiness of Interrupts.

\ GreenWaitOBF     ( -- )
\                  �`��ٹq�������I�O WaitOBF�C This word is used by waitkscan.

                   : GreenWaitOBF  \ wait until obf raised
                         begin
                           hlt     \ Stop CPU until next interrupt. �`��ٹq�C
                           kbcobf
                         until
                   ;

                   ' GreenWaitOBF 'waitOBF ! \ �}�l�i�H�C�{�� keyboard �ɳ��i�ٹq�F�I

// TSC , CPU Time-Stamp Counter

mywords definitions

\  rdtsc           ( -- tsc )
\                  CPU instruction RDTSC read 64 bits TSC.

                   : rdtsc
                       rax=0 rdx=0
                       <rdtsc>
                       [ 32 ] shl.rdx.n8 or.rax,rdx
                       $PUSH_RBX rbx=rax
                   ;

                   : (tsc-one-tick)       \ raw data
                     \ $Fe $21 iob! sti   \ enable IRQ0
                       $46c @             \ tick0
                       begin              \ tick0
                         dup $46c @       \ tick0 tick0 tick'
                       - -1 <= until
                       rdtsc >r           \                    [tsc1]
                       begin              \ tick0
                         dup $46c @       \ tick0 tick0 tick'
                       - -2 <= until
                       drop               \ empty
                       rdtsc r> -         \ tsc2-tsc1
                     \ $FF $21 iob!       \ disable IRQ0, to avoid all CPU time of VM works on it.
                   ;

                   : sort3  ( a b c -- a' b' c' )  \ sorted a>b>c
                       2dup < if swap then >r      \ a b' [c]
                       2dup < if swap then r>      \ a' b' c'
                       2dup < if swap then         \ a' b' c'
                   ;

                   : tsc-one-tick
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       sort3 drop swap drop \ �o�̥� mid sort �� average ��í�w�o�h�C
                   ;

\  tsc/ms          ( -- addr )
\                  Variable of �o�� CPU �C mS �� TSC ���ơC
\                  �����ʺA load �i�ӡA�H�K�A�����P���������A�C

                   variable tsc/ms
                   $Fe $21 iob!                          \ enable IRQ0
                   {sti}
                   tsc-one-tick 182 * 10000 / tsc/ms !   \ get TSC count in 1 mS

\  sleep           ( n -- )
\                  Sleep n mS

                   : sleep
                       tsc/ms @ * rdtsc + \ targetTSC
                       begin
                         dup              \ targetTSC targetTSC
                       rdtsc <= until     \ targetTSC targetTSC<=tsc
                       drop
                   ;

console definitions

                   : ClearKB ( -- ) \ clear keyboard buffer
                       begin
                         $60 iob@ drop \ drop all KBC data
                         5 sleep       \ delay 5 mS for KBC internal latency
                         kbcobf 0=     \ OBF all cleared
                       until
                   ;

                   ClearKB

// Scroll buffer
//                 �o�ӬO display buffer �X�i�C ���ù��W�w�g scroll �X�h�F�������٥i�H scroll �^�ӬݡC
//                 �Ӳz���ӥ� Scroll Lock ��Ӥ��� normal/scroll mode, �]�� Windows �U VM �i�ব����
//                 Scroll Lock key, �ҥH��� Ctrl Key �Ӥ����C���� Scroll mode ����ACursor �N�����F�A
//                 �Ѧ��ݥX�i�F Scroll mode, ���ɦ� Up, Down, PageUp, PageDown, Home, End �� key �i��
//                 �ӤW�U�u�� display buffer�C �o�ӥ\��u�b local �����W���ΡAremote control �L�ġA�]
//                 ����ĪG�n�̿� $B8000 display memory map ���S�ʡC

                   400 constant scrollbuffersize ( lines )
                   create scrollbuffer 80 2 * scrollbuffersize * dup allot scrollbuffer swap erase

                   : >scrollbuffer  ( -- )
                     scrollbuffer dup           \ buffer buffer
                     80 2 * + swap              \ buffer+(80*2) buffer ( from to )
                     scrollbuffersize 26 -      \ buffer+(80*2) buffer scrollbuffersize-26
                     80 * 2 *                   \ from to (scrollbuffersize-26)*80*2
                     cmove                      \ empty
                     $b8000                     \ $b8000 (from)
                     scrollbuffer               \ $b8000 buffer
                     scrollbuffersize 26 - 80 * 2 * + \ $b8000 buffer+(scrollbuffersize-26)*80*2
                     80 2 *                     \ from to length
                     cmove                      \ empty
                   ;

                   : newscroll  ( -- )
                     >scrollbuffer
                     $b8000 dup 80 2 * + swap 80 24 * 2 * cmove
                     80 24 * p2scr 80 2 * 0 fill
                   ;

                   : #screen    ( line# -- )  \ show screen start from line#
                     80 * 2 * scrollbuffer +  \ from
                     $b8000                   \ to
                     80 25 2 * *              \ length
                     cmove
                   ;

                   : ScrollLock
                     $b8000
                     scrollbuffer scrollbuffersize 25 - 80 * 2 * +
                     80 25 2 * *
                     cmove
                     scrollbuffersize 25 - >r      \ #line
                     begin
                       waitkscan  \ scan
                       dup 72 = if    \ up
                         r> 1- 0 max >r
                       then
                       dup 80 = if    \ down
                         r> 1+ scrollbuffersize 25 - min >r
                       then
                       dup 73 = if    \ page up
                         r> 25 - 0 max >r
                       then
                       dup 81 = if    \ page down
                         r> 25 + scrollbuffersize 25 - min >r
                       then
                       dup 71 = if    \ home
                         r> drop 0 >r
                       then
                       dup 79 = if    \ end
                         r> drop scrollbuffersize 25 - >r
                       then
                       r@ #screen
                     dup 29 = swap 28 = or until       \ Ctrl or Enter
                     r> drop
                     scrollbuffersize 25 - #screen
                   ;

                   ' newscroll 'scroll !  \ ���Ӫ� scroll �\�ഫ�����s�\��

// �ٹq���� ?rx , QEMU �����ɤ]�D�`�� CPU�C�[�W�� Ctrl key �� scroll �ù��A��n�ΤF�C

\  green?rx        ( -- F | ascii T )
\                  wait for a key press and then return ASCII code

                   : green?rx
                       position @ p2scr w@ if
                         hidecursor
                       else
                         showcursor
                       then
                       hlt \ CPU halt until next time tick. console?rx �����L�k�ٹq�A�����~�[�C
                       console?rx dup if
                         hidecursor
                         over 01 = if   \ I make Ctrl keys' ASCII code be 01 for ScrollLock control
                           ScrollLock   \ Press Crtl to enter ScrollLock mode
                           drop drop 0  \ drop
                         then
                       then
                   ;

                   ' green?rx '?key !   \ �e�s

debug definitions
                   ' *debug* alias *bp*
forth definitions
                   ' <=      alias =<
                   ' >=      alias =>
                   ' <>      alias !=

