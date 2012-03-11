;--------------------------------------------------------------------------------------------------------------
;  eforth64.asm
;  hcchen5600 2011/07/17 14:01:06 �ڲש�Q���դF�Aeforth64 should be org 0x100000 but MBR should be org 0x7c00 ,
;  due to that I'll use NASM without LINKer they must be separaged into two .asm files. That I have two source files,
;  "c:\Users\8304018.WKSCN\Documents\My Dropbox\learnings\BIOS DEBUGGER FORTH ENGIN\eforth64\...\MBR.asm"
;  "c:\Users\8304018.WKSCN\Documents\My Dropbox\learnings\BIOS DEBUGGER FORTH ENGIN\eforth64\...\eforth64.asm"

;  hcchen5600 2011/08/06 10:54:51
;  ���\�F�A eforth64 �b 64-bits MBR boot �_�Ӫ� Bochs VM �W�w�g�i�H����F�C�C
;  �`�����F code �令 64 bits ���O�H�~�A�� 64 bits �٦��X�Ӱ��D�C
;    1.  0< �n��A���Ӫ��g�k�u�A�� 16 bits�C UM/MOD UM* �̪� 15 �n�令 63�C
;    2.  LAST �H�ΩҦ� NFA link ���n�[�W COLDD base address. _LINK ��Ȥ]���O 0 ��� 0-COLDD�C
;        16 bits �ɬO .com �ɡA�S���o�Ӱ��D�C
;    3.  'FIND' �Ψ�@�� cell+ cell- , 16 bits system �o�˥Υ��n�O 2+ 2-�A 64 bits system �N����
;        �F�A���� cell+ cell- �Q���H�� 32bits 64bits �ܻ����C���e�� bytes �H�e�� @ ���n�{�令 w@ �~��C
;    4.  CALLL CALL, �]�n��g�A 64-bits �w�g���A�ΡC c, CCOMMA �����n�C�@�f��ɨ��Ҧ��� , c, w, d, ! c, w, d, @ c@ w@ d@
;    5.  Word name �令�����p�g�C
;  eforth64 �ק�����G
;    6.  r4 �A�X�ΨӶ}�o USB debug cable �����������C r5 ���F�n�b Bochs �W�����K�A�N�w�� BS EMIT , CRR EMIT ���ǭ׾�C
;    7.  digit? �[�X��A�O�j�p�g�����C
;    8.  (r6, r15) �g�X�F $eval ( string length -- ... ). (�� eval ���q�{�� TIB,#TIB�C)
;    9.  �s�� callsize+ �H���P�t�� call DOLST �� size �i�H���P�C
;   10.  r7 r8 �� r9 ���\�� assembly code �̪� console i/o ��Ӱ����ŴߡArun �_�ӥH��A�q forth source code �� install
;        console i/o �i�ӡC r9 �@�|�ﱼ�F�Ҧ��w�������D�C500K forth source ��X�� floppy image �̡A��g eforth64.f ����
;        �]�@�U build.bat �Y�i�۰ʲ��� floppy.img �b Bochs, QEMU �������C �H r9 �� v1.0 ���C hcchen5600 2011/08/13 23:34:01
;   11.  R16 ���� eforth 86ef202.asm �̦��� dump ������ assembly code �����C�Ҧ��w�g���� high level fcode ���F�賣�����C
;   12.  R19 Changed to STC. R20 supports vocabulary.
;===============================================================
; hcchen5600 100.11.29
; Based on Sir C. H. Ting's below 86eForth, it was DTC. Porting to 64 bits long mode.
; Switch to STC by copying Sir Sam Suan Chen and Sir Yap's weforth (or fsharp) STC words.
; Above modification log FYR.
;===============================================================
;       86eForth 2.02, C. H. Ting, 06/02/99
;       Add create, checksum, UPLOAD and DOWNLOAD.
;       A sample session looks like:
;               c>86ef202
;               DOWNLOAD LESSONS.TXT
;               WORDS
;               ' THEORY 'BOOT !
;               UPLOAD TEST.EXE
;               BYE
;               c>test
;
;       86eForth 2.01, C. H. Ting, 05/24/99
;       Merge Zen2.asm with eForth 1.12
;1.     Eliminate most of the @EXECUTE thru user variables
;2.     Combine name and code dictionary
;3.     Eliminate code pointer fields
;4.     elimiate catch-throw
;5.     eliminate most user variables
;6.     extend top memory to FFF0H where the stacks and user area are.
;7.     add open, close, read, write; improve BYE
;8      add 1+, 1-, 2/
;
;
;       eForth 1.12, C. H. Ting, 03/30/99
;               Change READ and LOAD to 'read' and 'load'.
;               Make LOAD to read and compile a file.  The file
;               buffer is from CP+1000 to NP-100.
;               To load all the lessons, type:
;                       LOAD LESSONS.TXT
;               and you can test all the examples in this file.
;       eForth 1.11, C. H. Ting, 03/25/99
;               Change BYE to use function 4CH of INT 21H.
;               Add read, write, open, close, READ, and LOAD
;               To read a text file into memory:
;                       HEX 2000 1000 READ TEST.TXT
;               READ returns the number of byte actually read.
;               To compile the source code in the text file:
;                       2000 FCD LOAD
;               where FCD is the length returned by READ.
;               These additions allow code for other eForth systems
;               to be tested on PC first.
;               It is part of the Firmware Engineering Workshop.
;
;
;   eForth 1.0 by Bill Muench and C. H. Ting, 1990
;   Much of the code is derived from the following sources:
;       8086 figForth by Thomas Newman, 1981 and Joe smith, 1983
;       aFORTH by John Rible
;       bFORTH by Bill Muench
;
;   The goal of this implementation is to provide a simple eForth Model
;   which can be ported easily to many 8, 16, 24 and 32 bit CPU's.
;   The following attributes make it suitable for CPU's of the '90:
;
;       small machine dependent kernel and portable high level code
;       source code in the MASM format
;       direct threaded code
;       separated code and name dictionaries
;       simple vectored terminal and file interface to host computer
;       aligned with the proposed ANS Forth Standard
;       easy upgrade path to optimize for specific CPU
;
;   You are invited to implement this Model on your favorite CPU and
;   contribute it to the eForth Library for public use. You may use
;   a portable implementation to advertise more sophisticated and
;   optimized version for commercial purposes. However, you are
;   expected to implement the Model faithfully. The eForth Working
;   Group reserves the right to reject implementation which deviates
;   significantly from this Model.
;
;   As the ANS Forth Standard is still evolving, this Model will
;   change accordingly. Implementations must state clearly the
;   version number of the Model being tracked.
;
;   Representing the eForth Working Group in the Silicon Valley FIG Chapter.
;   Send contributions to:
;
;       Dr. C. H. Ting
;       156 14th Avenue
;       San Mateo, CA 94402
;       (415) 571-7639
;
;===============================================================

;; Debugging switch

MOVEDTOFORTHCODE EQU 1                      ; Many words are not used in assembly code, they can be moved to forth code.
FAKESTDIO   EQU 1                           ; fake keyboard display, they will be provided by high level
                                            ; ���W�g�F�@�j�� console i/o ���{���A�u�O���F�}�o�Ϊ��N�[�A�{���g�n�F�N�n�ΪŴߧ�L�̨��N���C
                                            ; ���̲ת� USB debug cable i/o �{���Ӹm�����C�� forth �g�n���b�᭱�� $eval install �i�ӧY�i�C
;; Version control

VER         EQU 01                          ; major release version
EXT         EQU 20                          ; minor extension

;; Constants

TRUEE       EQU -1                          ;true flag

HIDE        EQU 020H                        ; Hide-Reveal is important for code end-code words, eforth �쪩�S���AForth code �̤~�X�{�C hcchen5600 2011/08/14 22:07:19
COMPO       EQU 040H                        ;lexicon compile only bit
IMEDD       EQU 080H                        ;lexicon immediate bit
MASKK       EQU 07F1FH                      ;lexicon bit mask  7F �O�� name 1st character bit7 mask ���A 1F �O�׶} HIDE COMPO IMEDD 3 bits.

CELLL       EQU 8                           ;size of a cell 64-bits now so it's 8 bytes  hcchen5600 2011/06/13 21:01:06
BASEE       EQU 10                          ;default radix
VOCSS       EQU 8                           ;depth of vocabulary stack

BKSPP       EQU 8                           ;back space
LF          EQU 10                          ;line feed
CRR         EQU 13                          ;carriage return
ERR         EQU 27                          ;error escape
TIC         EQU 39                          ;tick

RETT        EQU 0C3H                        ; ret opcode
CALLL       EQU 0E8H                        ;CALL opcode , when in 64-bits long mode it's 4 bytes relative target address hcchen5600 2011/08/06 22:03:16
CALLSIZE    EQU 5                           ;64-bits long mode call instruction total 5 bytes

;; Memory allocation

; hcchen5600 2011/07/17 11:38:33 �ڤ@��ı�o TIBB, UPP, SPP, RPP ���i�H�Y�p�A�]�� BIOS �����Ŷ����j�C��Ӥ@�Q�A����I���O
; 4k starting code �����D�CForth �����Q�δN�Τ��h�ޥL�C
; eforth64 memory map see "Evernote 2011/07/17 11:38 BIOS debug engine developing,  eforth memory map"

; In 64 bits version, I use long mode paging tables to create a world with one
; mega memory forth space. The 4k starting code can search the entire main memory
; for a block with all same value then use it and return to that value before ending.
; [ ] hcchen5600 2011/07/17 10:53:56

EM          EQU 1FFFF0H                     ;top of memory. In 16 bits real mode this value is simply a 16 bits offset.
                                            ;hcchen5600 2011/07/17 10:56:05 �ثe paging �Ŷ��w 2M�A�� EM �]�����Ŷ�����
                                            ;�ڳB�A�G�� 1FFFF0h.
US          EQU 64*CELLL                    ;user area size in cells
RTS         EQU 128*CELLL                   ;return stack/TIB size

UPP         EQU TIBB-RTS                    ;start of user area (UP0)
RPP         EQU UPP-RTS                     ;start of return stack (RP0)
TIBB        EQU EM-RTS                      ;terminal input buffer (TIB)
SPP         EQU UPP-8*CELLL                 ;start of data stack (SP0)

COLDD       EQU 100000h                     ; hcchen5600 2011/07/17 11:51:47 �Ψӫ��X memory map �� code �n�q����}�l�C
                                            ; ���갵���A�q 2M �� 100000h �}�l�C

                BITS    64               ;NASM 64 bits mode switch

;; Initialize assembly variables

        %assign _LINK 0-COLDD            ;force a null link �]���᭱�Ψ� _LINK ���令 _LINK+COLDD �ҥH�o�̽զ� 0-COLDD �p���Ĥ@�Ӥ~�|�O�s�C
        %assign _USER 0                  ;first user variable offset

;; Define assembly macros

%macro  $POP_RBX 0                       ; ( tos- rbx -- tos- ) Original ebx disappeared, ebx becomes new value from [ebp]
        mov     rbx,[rbp]
        lea     rbp,[rbp+CELLL]          ; �p�G���γo�ӤӪ�N ....
      ; add     rbp,CELLL                ; ²��[�k���󤣥i�H �|�ʨ� flag, �]������I
%endmacro

%macro  $PUSH_RBX 0                      ; ( rbx -- rbx rbx ) dup ebx value
        lea     rbp,[rbp-CELLL]          ; �p�G���γo�ӤӪ�N ....
      ; sub     rbp,CELLL                ; ²���k���󤣥i�H �|�ʨ� flag, �]������I
        mov     [rbp],rbx
%endmacro

;  Compile a code definition header.
%macro  $CODE   3                        ; %1, %2, %3 = LEX,NAME,LABEL
        DQ      _LINK+COLDD              ; token pointer and link
        %assign _LINK $-$$               ; link points to a name string
        DB      (%1+%3-$-1), %2          ; name string. (%3-$-1)�۰ʺ�X���סA-1 �O length �ۤv�����@�� byte ����A%1�O�ݩ�flags.
        %3:                              ; assembly label
%endmacro

;  Compile a colon definition header. For STC it's same as $CODE ���ܥh���C
%macro  $COLON  3                        ; %1, %2, %3 = LEX,NAME,LABEL
        $CODE   %1, %2, %3
%endmacro

;   Compile a user variable header.

%macro  $USER   3                        ; %1, %2, %3 = LEX,NAME,LABEL
        $CODE   %1, %2, %3
        CALL    DOUSE                    ; doUSER
        DQ      _USER                    ; offset
        %assign _USER _USER+CELLL        ; update user area offset
%endmacro

; branch �H�� ?brahcn �U����ءA�U���γ��C
; �@�جO���W�Φb assembly code �̪��A�N�O�o�ӡA�p�p�� macro �N�i�H�F�C
; �t�@�جO�n compile �i dictionary �̥h���A���N��M�n�g�� word�C
%macro  $BRAN   1                        ; BRANCH macro
        jmp     %1
%endmacro

%macro  $QBRAN  1                        ; ?BRANCH macro, jump when TOS==0
        or      rbx,rbx
        $POP_RBX
        jz      %1
%endmacro

; �H�e DOS eforth �� $NEXT �O code word �������ASTC model �� IP �N�O CPU �� IP register,
; �]�� $NEXT ��´N�O CPU return. ��F fsharp $NEXT �ܦ��O fort..next �� next. �� $NEXT
; �������� ret �����C

%macro  $NEXT   1                        ; for...NEXT MACRO
        call    DONXT
        DQ      %1                       ; relative adressing 14jun02sam
%endmacro


;; Main entry point

                org     COLDD

                ; �� fcode source backup �� 0x200000 �B, COLD �R�O�n���ƨϥΥL�C
                CLI
                CLD
                mov     rax,0x20008F     ; create 2M new page space $200000~$3fffff
                mov     [0xc008],rax
                mov     rcx,0x100000/8   ; length ���ܾ�ӳ��h,�d�� r17 ����q�C
                mov     rsi,0x100000     ; from
                mov     rdi,0x200000     ; to
                repz movsq
                jmp     COLD             ; ENTRY_POINT need to prepare source code first then call COLD.

;               ; r17 COLD will call this subroutine to restore the fcode source.
;               ; Here are some tricks, it works when they all work together.
;               ; I don't know whether both wbinvd and jmp rbx (instead of ret)
;               ; necessary.             -- R16 hcchen5600 2011/11/08 18:30:43
; RestoreCode:  CLD
;               mov     rcx,0x8000/8     ; length
;               mov     rsi,0x200000     ; from
;               mov     rdi,0x100000     ; to
;               repz movsq
;               wbinvd
;               mov     rbx,COLD0
;               jmp     rbx

; COLD start moves the following to USER variables. �o�ܭ��n�A����O�b COLD �ɴ����̨ꦨ��ȡC
; �Y�D�p���A���ǳQ��L���� COLD �]����_�A���W�N�|����C�Ҧ��Q�m���L�� deferred words ���ݤ��A���n�ܼƭȥ�M�C
; MUST BE IN SAME ORDER AS USER VARIABLES.

                align   16        ; align on 16-byte boundary
UZERO:
                DQ      BASEE     ; 1ff7f0  BASE
                DQ      0         ; 1ff7f8  tmp
                DQ      0         ; 1ff800  >IN
                DQ      0         ; 1ff808  #TIB
                DQ      TIBB      ; 1ff810  TIB
                DQ      INTER     ; 1ff818  'EVAL
                DQ      0         ; 1ff820  HLD
                DQ      0         ; 1ff828  CONTEXT pointer
                DQ      CTOP      ; 1ff830  CP
                DQ      LASTN     ; 1ff838  LAST     last word's NFA
                DQ      QRX       ; 1ff840  '?KEY    ?RX
                DQ      TXSTORE   ; 1ff848  'EMIT    TX!
                DQ      0         ; 1ff850  POSITION screen position
                DQ      HI        ; 1ff858  'BOOT COLD greeting
                DQ      BBKSLAA   ; 1ff860  '\    default is ' \(orig) , default back slash comment
                DQ      CELLL     ; 1ff868  reserve-word-fields RESERVEWORDFIELDS  for vocabulary
                DQ      NAMEQORIG ; 1ff870  'name?  TNAMEQ  for vocabulary
                DQ      SNAMEORIG ; 1ff878  '$,n    TSNAME  for vocabulary
                DQ      OVERTORIG ; 1ff880  'overt  TOVERT  for vocabulary
                DQ      SEMISORIG ; 1ff888  ';      TSEMIS  for vocabulary
                DQ      CREATORIG ; 1ff890  'create TCREATE for vocabulary
ULAST:          DQ      0,0,0,0

;   noop        ( --  )
;               NOP break point works with Bochsdbg.exe. We need this before console ready.
;               This is the first word, whereisit �|�Ψ�o�ӯS�ʡC

                $CODE   IMEDD,'noop',noop
                nop                    ; ��� nop, debug �]�_�I�ɤ�� ret �n�{�C
                ret

;   -1          ( -- -1 )
;               Minus One

                $CODE   0,'-1',MINUS1
                $PUSH_RBX              ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                mov     rbx,-1         ; �M���n��i TOS ���ȼg�i RBX
                ret

;   0           ( -- 0 )
;               Zero

                $CODE   0,'0',ZERO
                $PUSH_RBX              ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                xor     rbx,rbx        ; �M���n��i TOS ���ȼg�i RBX
                ret

;   1           ( -- 1 )
;               One

                $CODE   0,'1',ONE
                $PUSH_RBX              ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                mov     rbx,1          ; �M���n��i TOS ���ȼg�i RBX
                ret

;   2           ( -- 2 )
;               Two

                $CODE   0,'2',TWO
                $PUSH_RBX              ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                mov     rbx,2          ; �M���n��i TOS ���ȼg�i RBX
                ret

;   iob@        (port -- byte )
;               input a byte from the given i/o port

                $CODE   0,'iob@',INPORTB
                mov     rdx,rbx
                xor     rax,rax
                in      al,dx
                mov     rbx,rax
                ret

;   iob!        ( byte port -- )
;               output a byte to the given i/o port

                $CODE   0,'iob!',OUTPORTB
                mov     rdx,rbx
                $POP_RBX
                mov     rax,rbx
                $POP_RBX
                out     dx,al
                ret

;   ?rx         ( -- c T | F )
;   fake        Return input character and true, or a false if no input.
;               This is a fake word used before real word will be ready.

                $CODE   0,'?rx',QRX
                call    ZERO
                ret

;   tx!         ( c -- )
;   fake        putchar to stdout.
;               This is a fake word used before real word will be ready.

                $CODE   0,'tx!',TXSTORE
                call    DROP
                ret

;   ?key        ( -- c T | F )
;               Return input character and true, or a false if no input.

                $CODE   0,'?key',QKEY
                call    TQKEY
                jmp     ATEXE
              ; ret

;   emit        ( c -- )
;               Send character c to the output device.

                $CODE   0,'emit',EMIT
                call    TEMIT
                jmp     ATEXE
              ; ret

;; forth basics

;   doLIT       ( -- w )
;               Push an inline literal.

                $CODE   COMPO,'dolit',DOLIT
                $PUSH_RBX            ; �������� TOS push �i data stack
                pop      rax         ; pointer to the literal number
                mov      rbx,[rax]   ; get the number to TOS
                add      rax,CELLL   ; adjust the return point
                push     rax         ; �k�� return point
                ret

; [ ] doLIST �@�o STC �Τ��� -- R18 hcchen5600 2011/11/09 15:26:25
;   doLIST      ( a -- )
;               Process colon list.
;
;               $CODE   6,'dolist',DOLST
;               XCHG    rBP,rSP          ;exchange the return and data stack pointers
;               PUSH    rSI              ;push on return stack
;               XCHG    rBP,rSP          ;restore the pointers
;               POP     rSI              ;new list address
;               ret

;; Hardware reset

;   version     ( -- EXT VER)
;               Get this program's version

                $CODE   0,'version',VERSION
                $PUSH_RBX                 ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                mov     rbx,EXT           ; �M���n��i TOS ���ȼg�i RBX
                $PUSH_RBX                 ; �n���ȶi data stack, ���� TOS ������ȱ��U�h
                mov     rbx,VER           ; �M���n��i TOS ���ȼg�i RBX
                ret

;   hi          ( -- )
;               Display the sign-on message of eForth.

                $CODE   0,'hi',HI
                call    CR
                call    DOTQP
                DB      10,'eForth64 v'
                call    DOLIT
                DQ      VER
                call    DOT
                call    DOTQP
                DB      1,'.'
                call    DOLIT
                DQ      EXT
                call    DOT
                call    DOTQP
                DB      1,' '
                jmp     CR
              ; ret

; ENTRY_POINT   ( -- )
;               The hilevel cold start sequence.

                $CODE   0,'cold', COLD
                CLI
                CLD
                MOV     rBP,SPP          ; initialize SP
                MOV     rSP,RPP          ; initialize RP

COLD1:          call    DOLIT
                DQ      UZERO
                call    DOLIT
                DQ      UPP
                call    DOLIT
                DQ      ULAST-UZERO
                call    CMOVE            ; initialize user area
                call    PRESE            ; initialize data stack and TIB
                call    OVERT            ; necessary for $eval to add any new words
                call    sourcecode
                call    DOLIT
                DQ      0x100000
                call    PLUS             ; fcode source
                call    DOLIT
                DQ      512*1024         ; length
                call    SEVAL            ; $eval
                call    TBOOT
                call    ATEXE            ; application boot
                call    QUIT             ; start interpretation
                $BRAN   COLD             ; just in case

; [x] �@�o�C STC �Τ��� colon words �� return �{�ǤF�A�����N�O CPU �� ret ���O�C hcchen5600 2011/11/09 15:42:36
;   exit        ( -- )
;               Terminate a colon definition.
;
;               $CODE   0,'exit',EXIT
;               MOV     rSI,[rBP]        ;pop return address
;               ADD     rBP,CELLL        ;adjust RP
;               ret

;  donext       ( -- )                  STC hcchen5600 2011/11/11 09:18:38
;               Run time code for the single index loop.
;               : next ( -- ) \ hilevel model
;                 r> r> dup if 1 - >r @ >r exit then drop cell+ >r ;

                $CODE   COMPO,'donext',DONXT  ; [ -- ][ -- count ReturnAddress ]
                pop     rdi                   ; this function's return address points to the l-value of the for..next loop back point
                lea     rax , [rdi+CELLL]     ; get the address after $NEXT to eax, for end of loop.
                sub     qword [rsp],1         ; [ -- ][ -- count ] count--
                jb      nexta                 ; jb when 0 changed to -1
                jmp     [rdi]                 ; repeat the loop
nexta:                                        ;
              ; pop     rcx                   ; [ -- ][ count -- ] drop the counter
                add     rsp,CELLL             ; rsp+8 == rdrop  better than pop.rcx
                jmp     rax                   ; continue from next entry by skipping a word



;   ?branch     ( f -- )                STC hcchen5600 2011/11/11 09:18:38
;               Branch if flag is zero.

                $CODE   COMPO,'?branch',QBRAN
                or      rbx , rbx         ; is TOS true?
                $POP_RBX                  ; TOS consumed
                pop     rdi               ; get target pointer when TOS==NULL
                lea     rax , [rdi+CELLL] ; get target pointer when TOS!=NULL
                jne     BRAN1             ;
                jmp     [rdi]             ;
BRAN1:                                    ;
                jmp     rax               ;


;   branch      ( -- )                  STC hcchen5600 2011/11/11 09:18:38
;               Branch to an inline address.

                $CODE   COMPO,'branch',BRAN
                pop     rdi             ; get target pointer
                jmp     [rdi]           ; jmp to target

;   execute     ( ca -- )               STC hcchen5600 2011/11/11 09:02:27
;               Execute the word at ca.

                $CODE   0,'execute',EXECU
                mov     rax,rbx
                $POP_RBX
                jmp     rax             ; jump to the code address

;   !           ( q a -- )              STC hcchen5600 2011/11/11 09:18:38
;               Write data to memory c! , w! , e! , !  store 1 2 4 8 bytes respectively

                $CODE   0,'!',STORE
                mov     rax, [rbp]      ; data
                mov     [rbx], rax      ; (address) = data
                mov     rbx,[rbp+CELLL]
                add     rbp,CELLL*2     ; adjust RP
                ret

;   c!          ( c b -- )              STC hcchen5600 2011/11/11 09:18:38
;               Write data to memory

                $CODE   0,'c!',CSTORE
                mov     rax, [rbp]
                mov     [rbx],al
                mov     rbx, [rbp+CELLL]
                add     rbp,CELLL*2     ; adjust RP
                ret

;   w!          ( w a -- )             STC hcchen5600 2011/11/11 09:18:38
;               Write data to memory  c! , w! , d! and !

                $CODE   0,'w!',WSTORE
                mov     rax, [rbp]
                mov     [rbx],ax
                mov     rbx, [rbp+CELLL]
                add     rbp,CELLL*2     ; adjust RP
                ret

;   d!          ( d a -- )             STC hcchen5600 2011/11/11 09:18:38
;               Write data to memory

                $CODE   0,'d!',DSTORE   ; DSTOR has been used for 2!
                mov     rax, [rbp]
                mov     [rbx],eax
                mov     rbx, [rbp+CELLL]
                add     rbp,CELLL*2     ; adjust RP
                ret

;   @           ( a -- q )             STC hcchen5600 2011/11/11 09:18:38
;               Read memory   c@ w@ e@ @ : 1 2 4 8 bytes

                $CODE   0,'@',ATT
                mov     rbx,[rbx]
                ret

;   c@          ( b -- c )             STC hcchen5600 2011/11/11 09:18:38
;               Read memory

                $CODE   0,'c@',CAT
                xor     rax,rax
                mov     al,[rbx]
                mov     rbx,rax
                ret

;   w@          ( a -- w )             STC hcchen5600 2011/11/11 09:18:29
;               Read memory

                $CODE   0,'w@',WAT
                xor     rax,rax
                mov     ax,[rbx]
                mov     rbx,rax
                ret

;   d@          ( a -- d )             STC hcchen5600 2011/11/11 09:18:19
;               Read memory

                $CODE   0,'d@',DATT    ; DAT has been used for 2@
                xor     rax,rax
                mov     eax,[rbx]
                mov     rbx,rax
                ret

;   rp@         ( -- a )               STC hcchen5600 2011/11/11 10:12:34
;               Push the current RP to the data stack.

                $CODE   0,'rp@',RPAT
                pop     rax
                $PUSH_RBX
                mov     rbx,rsp
                JMP     rax

;   rp!         ( a -- )
;               Set the return stack pointer.

                $CODE   COMPO,'rp!',RPSTO
                POP     rax
                MOV     rsp,rbx
                $POP_RBX
                JMP     rax

;   r>          ( -- w )
;               Pop the return stack to the data stack.

              ; $CODE   COMPO+2,'r>',RFROM
              ; PUSH    QWORD [rBP]
              ; ADD     rBP,CELLL               ;adjust RP
              ; ret

                $CODE   0,'r>',RFROM
                $PUSH_RBX
                pop     rax                   ; �s�_�I ���Q�o�X�ӡH �o�ˬݨӡA R> �@�w�O CALL RFROM �i�Ӫ��C
                pop     rbx
                jmp     rax

;   r@          ( -- w )
;               Copy top of return stack to the data stack.

              ; $CODE   2,'r@',RAT
              ; PUSH    QWORD [rBP]
              ; ret

                $CODE   0,'r@',RAT
                $PUSH_RBX
                mov     rbx, [rsp+CELLL]      ; �V�L�ۤv�� return address ���U�@��
                ret



;   >r          ( w -- )
;               Push the data stack to the return stack.

                $CODE   COMPO,'>r',TOR          ; STC
                pop     rax
                push    rbx
                $POP_RBX
                jmp     rax


;   sp@         ( -- a )
;               Push the current data stack pointer.

              ; $CODE   3,'sp@',SPAT
              ; MOV     rBX,rSP                 ;use BX to index the data stack
              ; PUSH    rBX
              ; ret

                $CODE   0,'sp@',SPAT
                $PUSH_RBX
                mov     rbx,rbp
                ret

;   sp!         ( a -- )
;               Set the data stack pointer.

              ; $CODE   3,'sp!',SPSTO
              ; POP     rSP
              ; ret

                $CODE   0,'sp!',SPSTO
                mov     rbp,rbx
                $POP_RBX
                ret                               ; data stack reset , lodsd is not needed

;   drop        ( w -- )
;               Discard top stack item.

              ; $CODE   4,'drop',DROP
              ; ADD     rSP,CELLL               ;adjust SP
              ; ret

                $CODE   0,'drop',DROP
                $POP_RBX
                ret

;   dup         ( w -- w w )
;               Duplicate the top stack item.

              ; $CODE   3,'dup',DUPP
              ; MOV     rBX,rSP                 ;use BX to index the data stack
              ; PUSH    QWORD [rBX]
              ; ret

                $CODE   0,'dup',DUPP
                $PUSH_RBX
                ret

;   swap        ( w1 w2 -- w2 w1 )
;               Exchange top two stack items.

              ; $CODE   4,'swap',SWAP
              ; POP     rBX
              ; POP     rAX
              ; PUSH    rBX
              ; PUSH    rAX
              ; ret

                $CODE   0,'swap',SWAP
                mov     rax, [rbp]
                mov     [rbp], rbx
                mov     rbx, rax
                ret


;   over        ( w1 w2 -- w1 w2 w1 )
;               Copy second stack item to top.

              ; $CODE   4,'over',OVER
              ; MOV     rBX,rSP                   ;use BX to index the stack
              ; PUSH    QWORD [rBX+CELLL]
              ; ret

                $CODE   0,'over',OVER
                $PUSH_RBX
                mov     rbx, [rbp+CELLL]
                ret

;   0<          ( n -- t )
;               Return true if n is negative.

                $CODE   0,'0<',ZLESS
                sar     rbx,63
                ret

;   and         ( w w -- w )
;               Bitwise AND.

              ; $CODE   3,'and',ANDD
              ; POP     rBX
              ; POP     rAX
              ; AND     rBX,rAX
              ; PUSH    rBX
              ; ret

                $CODE   0,'and',ANDD
                and     rbx,[rbp]
                add     rbp,CELLL                 ; adjust RP
                ret

;   or          ( w w -- w )
;               Bitwise inclusive OR.

              ; $CODE   2,'or',ORR
              ; POP     rBX
              ; POP     rAX
              ; OR      rBX,rAX
              ; PUSH    rBX
              ; ret

                $CODE   0,'or',ORR
                or      rbx,[rbp]
                add     rbp,CELLL                 ; adjust RP
                ret

;   xor         ( w w -- w )
;               Bitwise exclusive OR.

              ; $CODE   3,'xor',XORR
              ; POP     rBX
              ; POP     rAX
              ; XOR     rBX,rAX
              ; PUSH    rBX
              ; ret

                $CODE   0,'xor',XORR
                xor     rbx,[rbp]
                add     rbp,CELLL                 ; adjust RP
                ret

;   um+         ( u u -- udsum )
;               Add two unsigned single numbers and return a double sum.

              ; $CODE   3,'um+',UPLUS
              ; XOR     rCX,rCX                   ;CX=0 initial carry flag
              ; POP     rBX
              ; POP     rAX
              ; ADD     rAX,rBX
              ; RCL     rCX,1                    ;get carry
              ; PUSH    rAX                      ;push sum
              ; PUSH    rCX                      ;push carry
              ; ret

                $CODE   0,'um+',UPLUS
                XOR     rax,rax                   ;CX=0 initial carry flag
                ADD     rbx,[rbp]
                RCL     rax,1                     ;get carry
                MOV     [rbp],rbx                 ;push sum
                MOV     rbx,rax
                ret

;; System and user variables

;   dovar       ( -- a )
;               Run time routine for VARIABLE and CREATE.

              ; $CODE   COMPO+5,'dovar',DOVAR
              ; DQ      RFROM,EXIT

                $CODE   COMPO,'dovar',DOVAR
                $PUSH_RBX
                pop     rbx
                ret                 ; �o�� ret �E�ݥ��`�A���ܶO�ѡC �ڥ� sketch pad 3 �e�F�i�ϸ� see my Evernote "��s eforth STC model doVAR ���g�k" hcchen5600 2011/11/11 13:09:20

;   up          ( -- a )
;               Pointer to the user area.
;               UP �����i user variables, �]�� access User variables �� doUSER �N�n�Ψ� UP, ����Φ�
;               �¦���l�N�O����C�٬O�Q�� up �ѥ[ cold init �ө�i�h�A���d���������Ϋ窺�����ѡC�u����C
;               �o��@�ӡA�z�פW cold �N�o���o�� up �]�w��ȡC�S�H��N�S�ơA�i�H�ٲ��C

                $CODE   0,'up',UP
                call    DOVAR
                DQ      UPP

;  sourcecode   ( -- a )
;               Pointer to the in-binary forth source area.

                $CODE   0,'sourcecode',sourcecode
              ; call    DOLIT
              ; DQ      forthcode
              ; ret
                $PUSH_RBX
                mov     rbx,forthcode
                ret

;   doUSER      ( -- a )
;               Run time routine for user variables.

                $CODE   COMPO,'douser',DOUSE
                call    RFROM
                call    ATT
                call    UP
                call    ATT
                jmp     PLUS

;   base        ( -- a )
;               Storage of the radix base for numeric I/O.

                $USER   0,'base',BASE

;   tmp         ( -- a )
;               A temporary storage location used in parse and find.

                $USER   COMPO,'tmp',TEMP

;   >in         ( -- a )
;               Hold the character pointer while parsing input stream.

                $USER   0,'>in',INN

;   #tib        ( -- a )
;               Hold the current count in and address of the terminal input buffer.

                $USER   0,'#tib',NTIB

;   <tib>       ( -- a )
;               Hold the base address of the terminal input buffer
;               TIB ���w�q�O���o r-value �G�ѥL�B�t�~�w�q�A�o�̳�O�d��m�Ӥ��� $USER �өw�q�X TIB�C

                %assign _USER _USER+CELLL

;   'eval       ( -- a )
;               Execution vector of EVAL.

                $USER   0,"'eval",TEVAL

;   hld         ( -- a )
;               Hold a pointer in building a numeric output string.

                $USER   0,'hld',HLD

;   context     ( -- a )
;               A area to specify vocabulary search order.

                $USER   0,'context',CNTXT

;   cp          ( -- a )
;               Point to the top of the code dictionary.

                $USER   0,'cp',CP

;   last        ( -- a )
;               Point to the last name in the name dictionary.

                $USER   0,'last',LAST

;   '?key       ( -- a )
;               Console input device. Normally is keyboard.

                $USER   0,"'?key",TQKEY

;   'emit       ( -- a )
;               Console output device. Normally is text display.

                $USER   0,"'emit",TEMIT

;   position    ( -- a )
;               80*25 screen linear position

                $USER   0,'position',POSITION

;   'boot       ( -- a )
;               The application startup vector.

                $USER   0,"'boot",TBOOT

;   '\          ( -- a )
;               Comment \ can be normal \ or // for console or source file respectively.

                $USER   0,"'\",TBKSLASH

;  reserve-word-fields (  -- addr )
;               �n�b�� 'colon :' �H�� 'create' �гy�s word ��, �b [link]'string' ���e�O�d LFA �Φh��X�� 
;               field �ܦ� [VFA][EFA][LFA]'string' �o�Ӱʧ@�� word �ӫO�d�O�̦n���A���o�򰵯u�����}�G�C
;               �o�򰵤]���⦳���D�A���i��O�̦n����k�C�ڹ惡����}�O word �̭��O�d cell �Ƨﰵ������
;               �γo���ܼƸѨM�C�Y�Q���� kernel �h���q�o�̤U�⤣���A�]�o�n�� $CODE macro�A�ڤ����򰵡C

                $USER   0,"reserve-word-fields", RESERVEWORDFIELDS

;   'name?      ( -- a )
;               These deferred words will need new version after supporting vocabulary 
    
                $USER   0,"'name?", TNAMEQ
    
;   '$,n        ( -- a )
;               These deferred words will need new version after supporting vocabulary 
    
                $USER   0,"'$,n",   TSNAME
    
;   'overt      ( -- a )
;               These deferred words will need new version after supporting vocabulary 
    
                $USER   0,"'overt", TOVERT
    
;   ';          ( -- a )
;               These deferred words will need new version after supporting vocabulary 
    
                $USER   0,"';",     TSEMIS
    
;   'create     ( -- a ) 
;               These deferred words will need new version after supporting vocabulary 

                $USER   0,"'create",TCREATE

;; Common functions

;   ?dup        ( w -- w w | 0 )
;               Dup tos if its is not zero.

                $CODE   0,'?dup',QDUP
                call    DUPP
                $QBRAN  QDUP1
                call    DUPP
QDUP1:          ret

;   rot         ( w1 w2 w3 -- w2 w3 w1 )
;               Rot 3rd item to top.

                $CODE   0,'rot',ROT
                call    TOR
                call    SWAP
                call    RFROM
                jmp     SWAP
              ; ret

;   2drop       ( w w -- )
;               Discard two items on stack.

                $CODE   0,'2drop',DDROP
                call    DROP
                jmp     DROP
              ; ret

;   2dup        ( w1 w2 -- w1 w2 w1 w2 )
;               Duplicate top two items.

                $CODE   0,'2dup',DDUP
                call    OVER
                jmp     OVER
              ; ret

;   +           ( w w -- sum )
;               Add top two items.

                $CODE   0,'+',PLUS
                call    UPLUS
                jmp     DROP
              ; ret

;   not         ( w -- w )
;               One's complement of tos.

                $CODE   0,'not',INVER
                call    MINUS1
                jmp     XORR
              ; ret

;   negate      ( n -- -n )
;               Two's complement of tos.

                $CODE   0,'negate',NEGAT
                call    INVER
                jmp     ONEP
              ; ret

;   dnegate     ( d -- -d )
;               Two's complement of top double.

                $CODE   0,'dnegate',DNEGA
                call    INVER
                call    TOR
                call    INVER
                call    ONE
                call    UPLUS
                call    RFROM
                jmp     PLUS
              ; ret

;   -           ( n1 n2 -- n1-n2 )
;               Subtraction.

                $CODE   0,'-',SUBB
                call    NEGAT
                call    PLUS
                ret

;   abs         ( n -- n )
;               Return the absolute value of n.

                $CODE   0,'abs',ABSS
                call    DUPP
                call    ZLESS
                $QBRAN  ABS1
                call    NEGAT
ABS1:           ret

;   =           ( w w -- t )
;               Return true if top two are equal.

                $CODE   0,'=',EQUAL
                call    XORR
                $QBRAN  EQU1
                call    ZERO       ; �o�̤��令 jmp ZERO �ȧ�ê�\Ū�z�ѡC
                ret
EQU1:           call    DOLIT
                DQ      TRUEE
                ret

;   u<          ( u u -- t )
;               Unsigned compare of top two items.

                $CODE   0,'u<',ULESS
                call    DDUP
                call    XORR
                call    ZLESS
                $QBRAN ULES1
                call    SWAP
                call    DROP
                call    ZLESS
                ret
ULES1:          call    SUBB
                call    ZLESS
                ret

;   <           ( n1 n2 -- t )
;               Signed compare of top two items.

                $CODE   0,'<',LESS
                call    DDUP
                call    XORR
                call    ZLESS
                $QBRAN  LESS1
                call    DROP
                call    ZLESS
                ret
LESS1:          call    SUBB
                call    ZLESS
                ret

;   max         ( n n -- n )
;               Return the greater of two top stack items.

                $CODE   0,'max',MAX
                call    DDUP
                call    LESS
                $QBRAN  MAX1
                call    SWAP
MAX1:           jmp     DROP
              ; ret

;   min         ( n n -- n )
;               Return the smaller of top two stack items.

                $CODE   0,'min',MIN
                call    DDUP
                call    SWAP
                call    LESS
                $QBRAN  MIN1
                call    SWAP
MIN1:           jmp     DROP
              ; ret

;   within      ( u ul uh -- t )
;               Return true if u is within the range of ul and uh. ( ul <= u < uh )

                $CODE   0,'within',WITHI
                call    OVER
                call    SUBB
                call    TOR
                call    SUBB
                call    RFROM
                jmp     ULESS
              ; ret

;; Divide

;   um/mod      ( udl udh un -- ur uq )
;               Unsigned divide of a double by a single. Return mod and quotient.

                $CODE   0,'um/mod',UMMOD
                call    DDUP
                call    ULESS
                $QBRAN  UMM4
                call    NEGAT
                call    DOLIT
                DQ      63     ; 15 for 16 bits, 63 for 64 bits system hcchen5600 2011/08/03 15:16:26
                call    TOR
UMM1:           call    TOR
                call    DUPP
                call    UPLUS
                call    TOR
                call    TOR
                call    DUPP
                call    UPLUS
                call    RFROM
                call    PLUS
                call    DUPP
                call    RFROM
                call    RAT
                call    SWAP
                call    TOR
                call    UPLUS
                call    RFROM
                call    ORR
                $QBRAN  UMM2
                call    TOR
                call    DROP
                call    ONEP
                call    RFROM
                $BRAN    UMM3
UMM2:           call    DROP
UMM3:           call    RFROM
                call    DONXT
                DQ      UMM1
                call    DROP
                jmp     SWAP
              ; ret
UMM4:           call    DROP
                call    DDROP
                call    MINUS1
                jmp     DUPP
              ; ret

;   m/mod       ( d n -- r q )
;               Signed floored divide of double by single. Return mod and quotient.

                $CODE   0,'m/mod',MSMOD
                call    DUPP
                call    ZLESS
                call    DUPP
                call    TOR
                $QBRAN  MMOD1
                call    NEGAT
                call    TOR
                call    DNEGA
                call    RFROM
MMOD1:          call    TOR
                call    DUPP
                call    ZLESS
                $QBRAN  MMOD2
                call    RAT
                call    PLUS
MMOD2:          call    RFROM
                call    UMMOD
                call    RFROM
                $QBRAN  MMOD3
                call    SWAP
                call    NEGAT
                call    SWAP
MMOD3:          ret

;   /mod        ( n n -- r q )
;               Signed divide. Return mod and quotient.

                $CODE   0,'/mod',SLMOD
                call    OVER
                call    ZLESS
                call    SWAP
                jmp     MSMOD
              ; ret

;   mod         ( n n -- r )
;               Signed divide. Return mod only.

                $CODE   0,'mod',MODD
                call    SLMOD
                jmp     DROP
              ; ret

;   /           ( n n -- q )
;               Signed divide. Return quotient only.

                $CODE   0,'/',SLASH
                call    SLMOD
                call    SWAP
                jmp     DROP
              ; ret

;; Multiply

;   um*         ( u u -- ud )
;               Unsigned multiply. Return double product.

                $CODE   0,'um*',UMSTA
                call    ZERO
                call    SWAP
                call    DOLIT
                DQ      63
                call    TOR      ; [x] 15 for 16 bits system, so I guess 63 for 64 bits hcchen5600 2011/08/03 15:16:35
UMST1:          call    DUPP
                call    UPLUS
                call    TOR
                call    TOR
                call    DUPP
                call    UPLUS
                call    RFROM
                call    PLUS
                call    RFROM
                $QBRAN UMST2
                call    TOR
                call    OVER
                call    UPLUS
                call    RFROM
                call    PLUS
UMST2:          call    DONXT
                DQ      UMST1
                call    ROT
                jmp     DROP
              ; ret

;   *           ( n n -- n )
;               Signed multiply. Return single product.

                $CODE   0,'*',STAR
                call    UMSTA
                jmp     DROP
              ; ret

;   m*          ( n n -- d )
;               Signed multiply. Return double product.

                $CODE   0,'m*',MSTAR
                call    DDUP
                call    XORR
                call    ZLESS
                call    TOR
                call    ABSS
                call    SWAP
                call    ABSS
                call    UMSTA
                call    RFROM
                $QBRAN MSTA1
                call    DNEGA
MSTA1:          ret

;   */mod       ( n1 n2 n3 -- r q )
;               Multiply n1 and n2, then divide by n3. Return mod and quotient.

                $CODE   0,'*/mod',SSMOD
                call    TOR
                call    MSTAR
                call    RFROM
                jmp     MSMOD
              ; ret

;   */          ( n1 n2 n3 -- q )
;               Multiply n1 by n2, then divide by n3. Return quotient only.

                $CODE   0,'*/',STASL
                call    SSMOD
                call    SWAP
                jmp     DROP
              ; ret

;; Miscellaneous

;   callsize+   ( a -- a+CALLSIZE )   hcchen5600 2011/08/09 17:46:06 �ڵo����,���o L-value(>in) �ɷ|�Ψ�C
;               Add CALLSIZE in byte to address.
;               This is useful when use CFA to get something in that word.

                $CODE   0,'callsize+',CALLSIZEP
                call    DOLIT
                DQ      CALLSIZE
                jmp     PLUS
              ; ret

;   cell+       ( a -- a )
;               Add cell size in byte to address.

                $CODE   0,'cell+',CELLP
                call    DOLIT
                DQ      CELLL
                jmp     PLUS
              ; ret

;   cell-       ( a -- a )
;               Subtract cell size in byte from address.

                $CODE   0,'cell-',CELLM
                call    DOLIT
                DQ      0-CELLL
                jmp     PLUS
              ; ret

;   cells       ( n -- n )
;               Multiply tos by cell size in bytes.

                $CODE   0,'cells',CELLS
                call    DOLIT
                DQ      CELLL
                jmp     STAR
              ; ret

;   1+          ( a -- a )
;               Equals to 1 +

                $CODE   0,'1+',ONEP
                call    ONE
                jmp     PLUS
              ; ret

;   1-          ( a -- a )
;               Equals to 1 -

                $CODE   0,'1-',ONEM
                call    MINUS1
                jmp     PLUS
              ; ret

;   2/          ( n -- n )
;               equals to 2 /

                $CODE   0,'2/',TWOSL
                call    TWO
                jmp     SLASH
              ; ret

;   bl          ( -- 32 )
;               Return 32, the blank character.

                $CODE   0,'bl',BLANK
                call    DOLIT
                DQ      32         ; space's ASCII
                ret

;   >char       ( c -- c )
;               Filter non-printing characters.

                $CODE   0,'>char',TCHAR
                call    DOLIT
                DQ      07FH
                call    ANDD
                call    DUPP    ;mask msb
                call    DOLIT
                DQ      127
                call    BLANK
                call    WITHI   ;check for printable
                $QBRAN TCHA1
                call    DROP
                call    DOLIT
                DQ      '.'     ;replace non-printables
TCHA1:          ret

;   depth       ( -- n )
;               Return the depth of the data stack.

                $CODE   0,'depth',DEPTH
                call    SPAT
                call    DOLIT
                DQ      SPP
                call    SWAP
                call    SUBB
                call    DOLIT
                DQ      CELLL
                jmp     SLASH
              ; ret

;   pick        ( ... +n -- ... w )
;               Copy the nth stack item to tos.

                $CODE   0,'pick',PICK
                call    ONEP
                call    CELLS
                call    SPAT
                call    PLUS
                jmp     ATT
              ; ret

;; Memory access

;   +!          ( n a -- )
;               Add n to the contents at address a.

                $CODE   0,'+!',PSTOR
                call    SWAP
                call    OVER
                call    ATT
                call    PLUS
                call    SWAP
                jmp     STORE
              ; ret

;   2!          ( d a -- )
;               Store the double integer to address a.

                $CODE   0,'2!',DSTOR
                call    SWAP
                call    OVER
                call    STORE
                call    CELLP
                jmp     STORE
              ; ret

;   2@          ( a -- d )
;               Fetch double integer from address a.

                $CODE   0,'2@',DAT
                call    DUPP
                call    CELLP
                call    ATT
                call    SWAP
                jmp     ATT
              ; ret

;   count       ( b -- b+1 n )
;               Return count byte of a string and add 1 to byte address.

                $CODE   0,'count',COUNT
                call    DUPP
                call    ONEP
                call    SWAP
                jmp     CAT
              ; ret

;   here        ( -- a )
;               Return the top of the code dictionary.

                $CODE   0,'here',HERE
                call    CP
                jmp     ATT
              ; ret

;   pad         ( -- a )
;               Return the address of the text buffer above the code dictionary.

                $CODE   0,'pad',PAD
                call    HERE
                call    DOLIT
                DQ      80
                jmp     PLUS
              ; ret

;   tib         ( -- a )
;               Return the address of the terminal input buffer.

                $CODE   0,'tib',TIB
                call    NTIB
                call    CELLP
                jmp     ATT
              ; ret               ; In user variable area TIB is next to #TIB.

;   @execute    ( a -- )
;               Execute vector stored in address a.

                $CODE   0,'@execute',ATEXE
                call    ATT
                call    QDUP                ;?address or zero
                $QBRAN EXE1
                call    EXECU                   ;execute if non-zero
EXE1:           ret                      ;do nothing if zero

;   cmove       ( b1 b2 u -- )
;               Copy u bytes from b1 to b2.

                $CODE   0,'cmove',CMOVE
                call    TOR
                $BRAN CMOV2
CMOV1:          call    TOR
                call    DUPP
                call    CAT
                call    RAT
                call    CSTORE
                call    ONEP
                call    RFROM
                call    ONEP
CMOV2:          call    DONXT
                DQ      CMOV1
                jmp     DDROP
              ; ret

;   fill        ( b u c -- )
;               Fill u bytes of character c to area beginning at b.

                $CODE   0,'fill',FILL
                call    SWAP
                call    TOR
                call    SWAP
                $BRAN FILL2
FILL1:          call    DDUP
                call    CSTORE
                call    ONEP
FILL2:          call    DONXT
                DQ      FILL1
                jmp     DDROP
              ; ret

;   erase       ( b u -- )
;               Erase u bytes beginning at b.

                $CODE   0,'erase',ERASE
                call    ZERO
                jmp     FILL
              ; ret

;   pack$       ( b u a -- a )
;               Build a counted string with u characters from b. Null fill.

                $CODE   0,'pack$',PACKS
                call    DUPP
                call    TOR          ;strings only on cell boundary
                call    DDUP
                call    CSTORE
                call    ONEP  ;save count
                call    SWAP
                call    CMOVE
                call    RFROM  ; �o�� r> ret ����令 jmp RFROM !!! �N�q���@�ˡC
                ret            ; move string

;; Numeric output, single precision

;   digit       ( u -- c )
;               Convert digit u to a character.

                $CODE   0,'digit',DIGIT
                call    DOLIT
                DQ      9
                call    OVER
                call    LESS
                call    DOLIT
                DQ      7
                call    ANDD
                call    PLUS
                call    DOLIT
                DQ      '0'
                jmp     PLUS
              ; ret

;   extract     ( n base -- n c )
;               Extract the least significant digit from n.

                $CODE   0,'extract',EXTRC
                call    ZERO
                call    SWAP
                call    UMMOD
                call    SWAP
                jmp     DIGIT
              ; ret

;   <#          ( -- )
;               Initiate the numeric output process.

                $CODE   0,'<#',BDIGS
              ; call    PAD
              ; call    HLD
              ; call    STORE
              ; ret

                CALL    PAD        ; pad
              ; CALL    ONEM       ; pad-1
                CALL    DUPP       ; pad-1 pad-1
                CALL    ZERO       ; pad-1 pad-1 0 Null ended string I guess
                CALL    SWAP       ; pad-1 0 pad-1
                CALL    CSTORE     ;
                CALL    HLD
                JMP     STORE


;   hold        ( c -- )
;               Insert a character into the numeric output string.

                $CODE   0,'hold',HOLD
                call    HLD
                call    ATT
                call    ONEM
                call    DUPP
                call    HLD
                call    STORE
                jmp     CSTORE
              ; ret

;   #           ( u -- u )
;               Extract one digit from u and append the digit to output string.

                $CODE   0,'#',DIG
                call    BASE
                call    ATT
                call    EXTRC
                jmp     HOLD
              ; ret

;   #s          ( u -- 0 )
;               Convert u until all digits are added to the output string.

                $CODE   0,'#s',DIGS
DIGS1:          call    DIG
                call    DUPP
                $QBRAN  DIGS2
                $BRAN   DIGS1
DIGS2:          ret

;   sign        ( n -- )
;               Add a minus sign to the numeric output string.

                $CODE   0,'sign',SIGN
                call    ZLESS
                $QBRAN SIGN1
                call    DOLIT
                DQ      '-'
                call    HOLD
SIGN1:          ret

;   #>          ( w -- b u )
;               Prepare the output string to be TYPE'd.

                $CODE   0,'#>',EDIGS
                call    DROP               ; empty
                call    HLD                ;
                call    ATT                ; hld@
                call    PAD                ; hld@ pad
                call    OVER               ; hld@ pad hld@
                jmp     SUBB               ; hld@ pad-hld@
              ; ret

;   str         ( w -- b u )
;               Convert a signed integer to a numeric string.

                $CODE   0,'str',STR
                call    DUPP
                call    TOR
                call    ABSS
                call    BDIGS
                call    DIGS
                call    RFROM
                call    SIGN
                jmp     EDIGS
              ; ret

;   hex         ( -- )
;               Use radix 16 as base for numeric conversions.

                $CODE   0,'hex',HEX
                call    DOLIT
                DQ      16
                call    BASE
                jmp     STORE
              ; ret

;   decimal     ( -- )
;               Use radix 10 as base for numeric conversions.

                $CODE   0,'decimal',DECIM
                call    DOLIT
                DQ      10
                call    BASE
                jmp     STORE
              ; ret

;; Numeric input, single precision

;   digit?      ( c base -- u t )
;               Convert a character to its numeric value. A flag indicates success.
;               ��� c �����j�g�A���令�j�p�g�q�Y  hcchen5600 2011/08/09 11:57:55

                $CODE   0,'digit?',DIGTQ
                call    TOR
                ; ---------- �令�j�p�g�q�Y ----------------------  hcchen5600 2011/08/09 12:02:29
                                     ; c [base]         try '9'     try 'a'
                call    DOLIT
                DQ      'a'-1             ; c 'a'-1          39 96       97 96
                call    OVER              ; c 'a'-1 c        39 96 39    97 96 97
                call    LESS              ; c 'a'-1<c lower? 39 96<39=0  97 96<97=-1
                $QBRAN  .isNOTlower       ; c                39          97
.islower:       call    DOLIT
                DQ      32                ; c 32                         97 32
                call    SUBB              ; c-32                         97-32=65='A'
.isNOTlower:                              ;                  39          65
                ; ------------------------------------------------
                call    DOLIT
                DQ      '0'
                call    SUBB
                call    DOLIT
                DQ      9
                call    OVER
                call    LESS
                $QBRAN DGTQ1
                call    DOLIT
                DQ      7
                call    SUBB
                call    DUPP
                call    DOLIT
                DQ      10
                call    LESS
                call    ORR
DGTQ1:          call    DUPP
                call    RFROM
                jmp     ULESS
              ; ret

;   number?     ( a -- n T | a F )
;               Convert a number string to integer. Push a flag on tos.

                $CODE   0,'number?',NUMBQ
                call    BASE
                call    ATT
                call    TOR
                call    ZERO
                call    OVER
                call    COUNT
                call    OVER
                call    CAT
                call    DOLIT
                DQ      '$'
                call    EQUAL
                $QBRAN NUMQ1
                call    HEX
                call    SWAP
                call    ONEP
                call    SWAP
                call    ONEM
NUMQ1:
                call    OVER
                call    CAT
                call    DOLIT
                DQ      '-'
                call    EQUAL
                call    TOR        ; addr len              [ base minus? ]
                call    SWAP       ; len  addr             [ base minus? ]
                call    RAT        ; len  addr minus?      [ base minus? ]
                call    SUBB       ; len  addr-minus?
                call    SWAP       ; addr len
                call    RAT        ; addr len minus?
                call    PLUS       ; addr len+minus?
                call    QDUP       ; addr len+minus? len+minus?
                $QBRAN NUMQ6
                call    ONEM       ; addr len+minus?-1     �@����פ��O 0
                call    TOR        ; addr [ base minus? len+minus?-1 ]
NUMQ2:
                call    DUPP
                call    TOR
                call    CAT
                call    BASE
                call    ATT
                call    DIGTQ
                $QBRAN NUMQ4         ; jump if not a number
                call    SWAP
                call    BASE
                call    ATT
                call    STAR
                call    PLUS
                call    RFROM
                call    ONEP
                $NEXT   NUMQ2        ; next digit
                call    RAT          ; all digits done
                call    SWAP
                call    DROP
                $QBRAN NUMQ3         ; positive number
                call    NEGAT
NUMQ3:
                call    SWAP         ; string flag
                $BRAN  NUMQ5
NUMQ4:                               ; not a number
                call    RFROM
                call    RFROM
                call    DDROP
                call    DDROP
                call    ZERO
NUMQ5:
                call    DUPP
NUMQ6:
                call    RFROM
                call    DDROP
                call    RFROM
                call    BASE
                jmp     STORE
              ; ret

;; Basic I/O

;   key         ( -- c )
;               Wait for and return an input character.

                $CODE   0,'key',KEY
KEY1:           call    QKEY    ; show-hide cursor is for eforth64 MBR floppy system only  hcchen5600 2011/08/07 17:16:42
                $QBRAN KEY1
                ret

;   nuf?        ( -- t )
;               Return false if no input, else pause and if CR return true.

                $CODE   0,'nuf?',NUFQ
                call    QKEY
                call    DUPP
                $QBRAN NUFQ1
                call    DDROP
                call    KEY
                call    DOLIT
                DQ      CRR
                call    EQUAL
NUFQ1:          ret

;   space       ( -- )
;               Send the blank character to the output device.

                $CODE   0,'space',SPACE
                call    BLANK
                jmp     EMIT
              ; ret

;   spaces      ( +n -- )
;               Send n spaces to the output device.

                $CODE   0,'spaces',SPACS
                call    ZERO
                call    MAX
                call    TOR
                $BRAN   CHAR2
CHAR1:          call    SPACE
CHAR2:          call    DONXT
                DQ      CHAR1
                ret

;   type        ( b u -- )
;               Output u characters from b.

                $CODE   0,'type',TYPES
                call    TOR
                $BRAN TYPE2
TYPE1:          call    DUPP
                call    CAT
                call    EMIT
                call    ONEP
TYPE2:          call    DONXT
                DQ      TYPE1
                jmp     DROP
              ; ret

;   cr          ( -- )
;               Output a carriage return and a line feed.

                $CODE   0,'cr',CR
                call    DOLIT
                DQ      CRR
                call    EMIT
                call    DOLIT
                DQ      LF
                jmp     EMIT
              ; ret

;   do$         ( -- a )
;               Return the address of a compiled string.

                $CODE   COMPO,'do$',DOSTR
                call    RFROM
                call    RAT
                call    RFROM
                call    COUNT
                call    PLUS
                call    TOR
                call    SWAP
                call    TOR    ; �o�� >r ret ����令 jmp >r �A �N�䤣�@�ˡC
                ret

;   $"|         ( -- a )
;               Run time routine compiled by $". Return address of a compiled string.

                $CODE   COMPO,'$"|',STRQP
                call    DOSTR                  ; force a call to do$
                ret              ; �o�� call dostr ret �]����令 jmp dostr �N�䤣�@�ˡI

;   ."|         ( -- )
;               Run time routine of ." . Output a compiled string.

                $CODE   COMPO,'."|',DOTQP
                call    DOSTR
                call    COUNT
                jmp     TYPES
              ; ret

;   .r          ( n +n -- )
;               Display an integer in a field of n columns, right justified.

                $CODE   0,'.r',DOTR
                call    TOR
                call    STR
                call    RFROM
                call    OVER
                call    SUBB
                call    SPACS
                call    TYPES
                ret

;   u.r         ( u +n -- )
;               Display an unsigned integer in n column, right justified.

                $CODE   0,'u.r',UDOTR
                call    TOR
                call    BDIGS
                call    DIGS
                call    EDIGS
                call    RFROM
                call    OVER
                call    SUBB
                call    SPACS
                jmp     TYPES
              ; ret

;   u.          ( u -- )
;               Display an unsigned integer in free format.

                $CODE   0,'u.',UDOT
                call    BDIGS
                call    DIGS
                call    EDIGS
                call    SPACE
                jmp     TYPES
              ; ret

;   .           ( w -- )
;               Display an integer in free format, preceeded by a space.

                $CODE   0,'.',DOT
                call    BASE
                call    ATT
                call    DOLIT
                DQ      10
                call    XORR      ;?decimal
                $QBRAN DOT1
                jmp     UDOT
              ; ret               ;no, display unsigned
DOT1:           call    STR
                call    SPACE
                jmp     TYPES
              ; ret               ;yes, display signed

;   ?           ( a -- )
;               Display the contents in a memory cell.

                $CODE   0,'?',QUEST
                call    ATT
                jmp     DOT
              ; ret

;; Parsing

;   parse       ( b u c -- b u delta ; <string> )
;               Scan string delimited by c. Return found string and its offset.
;               b string buffer address, usually is TIB >IN @ +
;               u is string length, usually is #TIB @ >IN @ -
;               delta is the length of the parsed word

                $CODE   0,'<parse>',PARS
                call    TEMP
                call    STORE
                call    OVER
                call    TOR
                call    DUPP
                $QBRAN PARS8
                call    ONEM
                call    TEMP
                call    ATT
                call    BLANK
                call    EQUAL
                $QBRAN PARS3
                call    TOR
PARS1:          call    BLANK
                call    OVER
                call    CAT
                call    SUBB
                call    ZLESS
                call    INVER
                $QBRAN PARS2
                call    ONEP
                call    DONXT
                DQ      PARS1
                call    RFROM
                call    DROP,
                call    ZERO
                jmp     DUPP
              ; ret
PARS2:          call    RFROM
PARS3:          call    OVER
                call    SWAP
                call    TOR
PARS4:          call    TEMP
                call    ATT
                call    OVER
                call    CAT
                call    SUBB
                call    TEMP
                call    ATT
                call    BLANK
                call    EQUAL
                $QBRAN PARS5
                call    ZLESS
PARS5:          $QBRAN PARS6
                call    ONEP
                call    DONXT
                DQ      PARS4
                call    DUPP
                call    TOR
                $BRAN PARS7
PARS6:          call    RFROM
                call    DROP
                call    DUPP
                call    ONEP
                call    TOR
PARS7:          call    OVER
                call    SUBB
                call    RFROM
                call    RFROM
                jmp     SUBB
              ; ret
PARS8:          call    OVER
                call    RFROM
                jmp     SUBB
              ; ret

;   parse       ( c -- b u ; <string> )
;               Scan input stream and return counted string delimited by c.

                $CODE   0,'parse',PARSE
                call    TOR
                call    TIB
                call    INN
                call    ATT
                call    PLUS     ; current input buffer pointer
                call    NTIB
                call    ATT
                call    INN
                call    ATT
                call    SUBB     ; remaining count
                call    RFROM
                call    PARS
                call    INN
                jmp     PSTOR
              ; ret

;   .(          ( -- )
;               Output following string up to next ) .

                $CODE   IMEDD,'.(',DOTPR
                call    DOLIT
                DQ      ')'
                call    PARSE
                jmp     TYPES
              ; ret

;   (           ( -- )
;               Ignore following string up to next ) . A comment.

                $CODE   IMEDD,'(',PAREN
                call    DOLIT
                DQ      ')'
                call    PARSE
                jmp     DDROP
              ; ret

;   \(orig)         ( -- )
;               Ignore following text till the end of line.

                $CODE   IMEDD,'\(orig)',BBKSLAA
                call    NTIB
                call    ATT
                call    INN
                jmp     STORE
              ; ret

;   \           ( -- )
;               Ignore following text till the end of line.

                $CODE   IMEDD,'\',BKSLA
                call    TBKSLASH
                jmp     ATEXE
              ; ret

;   word        ( c -- a ; <string> )
;               Parse a word from input stream and copy it to code dictionary.
;               The return address points to the counted string. But before the string there can be some
;               reserved cells depends on reserve-word-fields@.
;               �p�G counted string a �����׬O 0 �N��ܧ�M�F�A�S��ۡC

                $CODE   0,'word',WORDD
                call    PARSE                ; parse ���o�� counted string
                call    HERE
                call    RESERVEWORDFIELDS
                call    ATT
                call    PLUS                 ; ��n dictionary �̦s�񪺦a��
                jmp     PACKS                ; ( s u a -- a ) �q PAD �̧� string �h�i dictionary �̨ӡC
              ; ret

;   token       ( -- a ; <string> )
;               Parse a word from input stream and copy it to name dictionary.
;               a points to a counted string at HERE , �p�G counted string a �����׬O 0 �N��ܨS���F�C

                $CODE   0,'token',TOKEN
                call    BLANK
                jmp     WORDD
              ; ret

;; Dictionary search

;   name>       ( na -- ca )
;               Return a code address given a name address.

                $CODE   0,'name>',NAMET
                call    COUNT
                call    DOLIT
                DQ      31
                call    ANDD
                jmp     PLUS
              ; ret

;   same?       ( a a u -- a a f \ -0+ )
;               Compare u bytes in two strings. Return 0 if identical.

                $CODE   0,'same?',SAMEQ
                call    ONEM
                call    TOR
                $BRAN SAME2
SAME1:          call    OVER
                call    RAT
                call    PLUS
                call    CAT
                call    OVER
                call    RAT
                call    PLUS
                call    CAT
                call    SUBB
                call    QDUP
                $QBRAN SAME2
                call    RFROM
                jmp     DROP
              ; ret
SAME2:          call    DONXT
                DQ      SAME1
                jmp     ZERO
              ; ret

; ��g 1 byte ���ץ���, ���G����A�P find �t�󤣤W�C hcchen5600 2011/11/25 15:18:29
;;   same?       ( a a u -- a a f \ -0+ )
;;               Compare u bytes in two strings. Return 0 if identical.
;;               hcchen5600 2011/11/25 12:02:17 I corrected it. Abover original version �֤�@�� char.
;
;                $CODE   0,'same?',SAMEQ
;              ; call    ONEM              ; a1 a2 len-1
;                call    TOR               ; a1 a2 [len]     for aft
;                $BRAN SAME2               ;
;SAME1:          call    OVER              ; a1 a2 a1
;                call    RAT               ; a1 a2 a1 len-1  count-- was done by DONXT.
;              ; call    ONEM              ; a1 a2 a1 len-1
;                call    PLUS              ; a1 a2 a1+len-1
;                call    CAT               ; a1 a2 char(a1+len-1)
;                call    OVER              ; a1 a2 char(a1+len-1) a2
;                call    RAT               ; a1 a2 char(a1+len-1) a2 len
;              ; call    ONEM              ; a1 a2 char(a1+len-1) a2 len-1
;                call    PLUS              ; a1 a2 char(a1+len-1) a2+len-1
;                call    CAT               ; a1 a2 char(a1+len-1) char(a2+len-1)
;                call    SUBB              ; a1 a2 char(a1+len-1)-char(a2+len-1)
;                call    QDUP              ; a1 a2 (cmp cmp | 0 )
;                $QBRAN SAME2              ; a1 a2     go on to next char if this char is same
;                call    RFROM             ; a1 a2 cmd len-1 [empty]
;                call    DROP              ; a1 a2 cmd
;                ret                       ;
;SAME2:          call    DONXT             ; a1 a2           then next count--
;                DQ      SAME1             ;
;                call    ZERO              ; a1 a2 0
;                ret


;   find        ( a va -- ca na | a F )
;               Search a vocabulary for a string. Return ca and na if succeeded.

                $CODE   0,'find',FIND
                call    SWAP
                call    DUPP
                call    CAT
                call    TEMP
                call    STORE
                call    DUPP
                call    WAT
                call    TOR
                call    TWO
                call    PLUS
                call    SWAP
FIND1:          call    ATT
                call    DUPP
                $QBRAN FIND6
                call    DUPP
                call    ATT
                call    DOLIT
                DQ      MASKK
                call    ANDD
                call    RAT
                call    XORR
                $QBRAN FIND2
                call    TWO
                call    PLUS
                call    MINUS1
                $BRAN FIND3
FIND2:          call    TWO
                call    PLUS
                call    TEMP
                call    ATT
                call    SAMEQ
FIND3:          $BRAN FIND4
FIND6:          call    RFROM
                call    DROP
                call    SWAP
                call    TWO
                call    SUBB
                jmp     SWAP
              ; ret
FIND4:          $QBRAN FIND5
                call    TWO
                call    SUBB
                call    CELLM
                $BRAN FIND1
FIND5:          call    RFROM
                call    DROP
                call    SWAP
                call    DROP
                call    TWO
                call    SUBB
                call    DUPP
                call    NAMET
                jmp     SWAP
              ; ret

;   name?       ( a -- ca na | a F )
;               Search all context vocabularies for a string.

                $CODE   0,'name?(orig)',NAMEQORIG
                call    CNTXT
                jmp     FIND

                $CODE   0,'name?',NAMEQ
                call    TNAMEQ
                jmp     ATEXE

;; Terminal response

;   ^h          ( bot eot cur -- bot eot cur )
;               Backup the cursor by one character.

                $CODE   0,'^h',BKSP
                call    TOR
                call    OVER
                call    RFROM
                call    SWAP
                call    OVER
                call    XORR
                $QBRAN BACK1
                call    DOLIT
                DQ      BKSPP
                call    EMIT
                call    ONEM
                call    BLANK
                call    EMIT
                call    DOLIT
                DQ      BKSPP
                call    EMIT
BACK1:          ret

;   tap         ( buffer c -- buffer+1 )
;               Echo and store the key stroke, buffer++ for the next key     - hcchen5600 2011/08/07 10:41:41

                $CODE   0,'tap',TAP
                call    DUPP                            ; b0 b1 c c
                call    EMIT                            ; b0 b1 c
                call    OVER                            ; b0 b1 c b1
                call    CSTORE                          ; b0 b1
                jmp     ONEP                            ; b0 b1+1
              ; ret

;   ktap        ( bot eot cur c -- bot eot cur )
;               Process a key stroke, CR or backspace.

                $CODE   0,'ktap',KTAP
                call    DUPP
                call    DOLIT
                DQ      CRR
                call    XORR
                $QBRAN KTAP2
                call    DOLIT
                DQ      BKSPP
                call    XORR
                $QBRAN KTAP1
                call    BLANK
                jmp     TAP
              ; ret
KTAP1:          jmp     BKSP
              ; ret
KTAP2:          call    DROP
                call    SWAP
                call    DROP
                jmp     DUPP
              ; ret

;   accept      ( b u -- b u )
;               Accept characters to input buffer. Return with actual count.

                $CODE   0,'accept',ACCEP
                call    OVER
                call    PLUS
                call    OVER
ACCP1:          call    DDUP
                call    XORR
                $QBRAN ACCP4
                call    KEY
                call    DUPP
                call    BLANK
                call    DOLIT
                DQ      127
                call    WITHI
                $QBRAN ACCP2
                call    TAP
                $BRAN ACCP3
ACCP2:          call    KTAP
ACCP3:          $BRAN ACCP1
ACCP4:          call    DROP
                call    OVER
                jmp     SUBB
              ; ret

;   query       ( -- )
;               Accept input stream to terminal input buffer.

                $CODE   0,'query',QUERY
                call    TIB
                call    DOLIT
                DQ      80
                call    ACCEP
                call    NTIB
                call    STORE
                call    DROP
                call    ZERO
                call    INN
                jmp     STORE
              ; ret

;   abort       ( -- )
;               Reset data stack and jump to QUIT.

                $CODE   0,'abort',ABORT
                call    PRESE
                call    DOTOK    ; abort is used for dropall thus .ok is better
                jmp     QUIT

;  <?abort">    ( f -- )
;               Run time routine of ABORT" . Abort with a message.
;               f=1 �ɦL�X�򱵵۪� string �M�� abort�C�_�h�����ơC

                $CODE   COMPO,'<?abort">',ABORQ
                $QBRAN ABOR2             ;text flag
                call    DOSTR            ; ���o 2'nd level return stack �ҫ��� string. �� return ��}���L��string.
; �o���I�ܼ����C�q�~�����i�Ӫ����|�ܦh�I
ABOR1:          call    SPACE
                call    COUNT
                call    TYPES
                call    DOLIT
                DQ      '?'
                call    EMIT
                call    CR
                call    ABORT  ;pass error string
ABOR2:          call    DOSTR
                jmp     DROP
              ; ret         ;drop error

;; The text interpreter

;   $interpret  ( a -- )
;               Interpret a word. If failed, try to convert it to an integer.

                $CODE   0,'$interpret',INTER
                call    NAMEQ
                call    QDUP              ;?defined
                $QBRAN INTE1
                call    ATT
                call    DOLIT
                DQ      COMPO
                call    ANDD     ;?compile only lexicon bits
                call    ABORQ
                DB      13,' compile only'
                jmp     EXECU
              ; ret              ;execute defined word
INTE1:          call    NUMBQ            ;convert a number
                $QBRAN ABOR1
                ret

;   [           ( -- )
;               Start the text interpreter.

                $CODE   IMEDD,'[',LBRAC
                call    DOLIT
                DQ      INTER
                call    TEVAL
                jmp     STORE
              ; ret

;   .OK         ( -- )
;               Display 'ok' only while interpreting.

                $CODE   0,'.ok',DOTOK
                call    DOLIT
                DQ      INTER
                call    TEVAL
                call    ATT
                call    EQUAL
                $QBRAN DOTO1
                call    DOTQP
                DB      3,' ok'
DOTO1:          jmp     CR
              ; ret

;   ?STACK      ( -- )
;               Abort if the data stack underflows.

                $CODE   0,'?stack',QSTAC
                call    DEPTH
                call    ZLESS             ;check only for underflow
                call    ABORQ
                DB      11,' underflow '
                ret

;   EVAL        ( -- )
;               Interpret the input stream.

                $CODE   0,'eval',EVAL
EVAL1:          call    TOKEN
                call    DUPP
                call    CAT          ;?input stream empty
                $QBRAN EVAL2
                call    TEVAL
                call    ATEXE
                call    QSTAC       ;evaluate input, check stack
                $BRAN EVAL1
EVAL2:          jmp     DROP
              ; ret                 ;prompt

;   $eval       ( a u -- )
;               Run the given string.

                $CODE   0,'$eval',SEVAL
                call    INN              ; a u >IN
                call    ATT              ; a u (>IN)
                call    TOR              ; a u [ (>in) ]
                call    NTIB             ; a u #tib
                call    ATT              ; a u (#tib)
                call    TOR              ; a u [ (>in) (#tib) ]
                call    TIB              ; a u tib
                call    TOR              ; a u [ (>in) (#tib) tib ]
                call    DOLIT            ; a u
                DQ      INN              ; a u INN     INN is the assembly label
                call    CALLSIZEP        ; a u INN+5   skip the call DOUSR'5 5 bytes get to the variable l-value
                call    ATT              ; a u (INN+5) get the offset of INN in user variable area
                call    UP               ; a u
                call    ATT              ; a u         user variable area starting point
                call    PLUS             ; a u >in variable location
                call    DUPP             ; a u >in >in
                call    ZERO             ; a u
                call    SWAP             ; a u >in 0 >in
                call    STORE            ; a u >in          >in == 0 , clear >in
                call    CELLP            ; a u #TIB
                call    DDUP             ; a u #TIB u #TIB
                call    STORE            ; a u #TIB         #TIB == u
                call    CELLP            ; a u TIB
                call    SWAP             ; a TIB u
                call    DROP             ; a TIB
                call    SWAP             ; TIB a
                call    OVER             ; TIB a TIB
                call    STORE            ; TIB              TIB == a
                call    TOR              ; empty     [ (>in) (#tib) tib TIB ]
                call    EVAL             ; ...
                call    RFROM            ; ... TIB       [ (>in) (#tib) tib ]
                call    RFROM            ; ... TIB tib   [ (>in) (#tib) ]
                call    OVER             ; ... TIB tib TIB
                call    STORE            ; ... TIB              TIB == tib , restore original TIB value
                call    CELLM            ; ... #TIB
                call    RFROM            ; ... #TIB (#tib)  [ (>in) ]
                call    OVER             ; ... #TIB (#tib) #TIB
                call    STORE            ; ... #TIB             #TIB == (#tib) , restore original #tib value
                call    CELLM            ; ... >in
                call    RFROM            ; ... >in (>in) [ empty ]
                call    SWAP             ; ... (>in) >in
                jmp     STORE            ; ...                  restore >in
              ; ret

;   PRESET      ( -- )
;               Reset data stack pointer and the terminal input buffer.

                $CODE   0,'preset',PRESE
                call    DOLIT
                DQ      SPP
                call    SPSTO
                call    DOLIT
                DQ      TIBB
                call    NTIB
                call    CELLP
                jmp     STORE
              ; ret

;   QUIT        ( -- )
;               Reset return stack pointer and start text interpreter.

                $CODE   0,'quit',QUIT
                call    DOLIT
                DQ      RPP
                call    RPSTO         ;reset return stack pointer
QUIT1:          call    LBRAC                   ;start interpretation
QUIT2:          call    QUERY                   ;get input to TIB
                call    EVAL
                call    DOTOK              ;'eval @execute
                $BRAN QUIT2              ;continue till error

;; The compiler

;   '           ( -- ca )
;               Search context vocabularies for the next word in input stream.

                $CODE   0,"'",TICK
                call    TOKEN
                call    NAMEQ             ;?defined
                $QBRAN ABOR1
                ret                       ;yes, push code address

; �ڷd������ eforth86 �̨S�� ['] �F�A�]���Τ��۩�b .asm �̡C['] >IN �g�� DOLIT,INN �Y�i.
;  [']          ( -- ca )
;               Search context vocabularies for the next word in colon definition.

;   ALLOT       ( n -- )
;               Allocate n bytes to the code dictionary.

                $CODE   0,'allot',ALLOT
                call    CP
                jmp     PSTOR
              ; ret           ;adjust code pointer

;   ,           ( w -- )
;               Compile an integer into the code dictionary.

                $CODE   0,',',COMMA
                call    HERE
                call    DUPP
                call    CELLP         ;cell boundary
                call    CP
                call    STORE
                jmp     STORE
              ; ret                   ;adjust code pointer and compile

;   c,          ( c -- )
;               Compile a byte into the code dictionary.

                $CODE   0,'c,',CCOMMA
                call    HERE
                call    DUPP
                call    ONEP          ;cell boundary
                call    CP
                call    STORE
                jmp     CSTORE
              ; ret                  ;adjust code pointer and compile

;   w,          ( w -- )
;               Compile a word 16-bits into the code dictionary.

                $CODE   0,'w,',WCOMMA
                call    HERE
                call    DUPP
                call    TWO
                call    PLUS  ;cell boundary
                call    CP
                call    STORE
                jmp     WSTORE
              ; ret             ;adjust code pointer and compile

;   d,          ( d -- )
;               Compile a double word 32-bits into the code dictionary.

                $CODE   0,'d,',DCOMMA
                call    HERE
                call    DUPP
                call    DOLIT
                DQ      4
                call    PLUS  ;cell boundary
                call    CP
                call    STORE
                jmp     DSTORE
              ; ret           ;adjust code pointer and compile

;   [COMPILE]   ( -- ; <string> )
;               Compile the next immediate word into code dictionary.

                $CODE   IMEDD,'[compile]',BCOMP
                call    TICK
                jmp     CALLC
              ; ret

;   COMPILE     ( -- )
;               Compile the next address in colon list to code dictionary.

              ; $CODE   COMPO,'compile',COMPI      ; DTC version
              ; call    RFROM     ; get RTOS to TOS, RTOS is address of the word to be compiled into dictionary
              ; call    DUPP      ; addr addr
              ; call    ATT       ; addr (addr)  where (addr) is the word to be compiled
              ; call    COMMA     ; addr         compile (addr) into dictionary
              ; call    CELLP     ; addr+cell    adjust return address
              ; call    TOR       ; empty
              ; ret               ;

                $COLON  COMPO,'compile',COMPI      ; STC version
                CALL    RFROM        ; addr        get RTOS to TOS, RTOS is this function's return address!
                CALL    ONEP         ; addr+1      skip the CALL instruction
                CALL    DUPP         ; addr+1 addr+1
                CALL    ATT          ; addr+1 (addr+1)   get the relative address
                CALL    SWAP         ; (addr+1) addr+1
                CALL    DOLIT
                DQ      4
                CALL    PLUS         ; (addr+1) addr+1+4           adjust return address
                CALL    DUPP         ; (addr+1) addr+1+4 addr+1+4
                CALL    TOR          ; (addr+1) addr+1+4           settledown return address
                CALL    PLUS         ; target                      �o�̫D�`�}�G�I see my Evernote "eforth ��s STC �� compile �p����o target CFA?" hcchen5600 2011/11/12 01:06:51
                jmp     CALLC        ; compile 'call target'
              ; ret                  ; empty                       adjusted return address


;   LITERAL     ( w -- )
;               Compile TOS to code dictionary as an integer literal.

                $CODE   IMEDD,'literal',LITER
                call    COMPI        ;
                call    DOLIT
                jmp     COMMA

;   $,"         ( -- )
;               Compile a literal string up to next " .

                $CODE   0,'$,"',STRCQ
                call    DOLIT
                DQ      '"'
                call    PARSE
                call    HERE
                call    PACKS       ;string to code dictionary
                call    COUNT
                call    PLUS        ;calculate aligned end of string
                call    CP
                jmp     STORE
              ; ret                 ;adjust the code pointer

;; Structures

;   FOR         ( n -- a )
;               Start a FOR-NEXT loop structure in a colon definition.

                $CODE   IMEDD,'for',FOR
                call    COMPI
                call    TOR
                jmp     HERE
              ; ret

;   BEGIN       ( -- a )
;               Start an infinite or indefinite loop structure.

                $CODE   IMEDD,'begin',BEGIN
                jmp     HERE
              ; ret

;   NEXT        ( a -- )
;               Terminate a FOR-NEXT loop structure.

                $CODE   IMEDD,'next',NEXT
                call    COMPI
                call    DONXT
                jmp     COMMA
              ; ret

;   UNTIL       ( a -- )
;               Terminate a BEGIN-UNTIL indefinite loop structure.

                $CODE   IMEDD,'until',UNTIL
                call    COMPI
                call    QBRAN
                jmp     COMMA
              ; ret

;   AGAIN       ( a -- )
;               Terminate a BEGIN-AGAIN infinite loop structure.

                $CODE   IMEDD,'again',AGAIN
                call    COMPI
                call    BRAN
                jmp     COMMA
              ; ret

;   IF          ( -- A )
;               Begin a conditional branch structure.

                $CODE   IMEDD,'if',IFF
                call    COMPI
                call    QBRAN
                call    HERE
                call    ZERO
                jmp     COMMA
              ; ret

;   AHEAD       ( -- A )
;               Compile a forward branch instruction.

                $CODE   IMEDD,'ahead',AHEAD
                call    COMPI
                call    BRAN
                call    HERE
                call    ZERO
                jmp     COMMA
              ; ret

;   REPEAT      ( A a -- )
;               Terminate a BEGIN-WHILE-REPEAT indefinite loop.

                $CODE   IMEDD,'repeat',REPEA
                call    AGAIN
                call    HERE
                call    SWAP
                jmp     STORE
              ; ret

;   THEN        ( A -- )
;               Terminate a conditional branch structure.

                $CODE   IMEDD,'then',THENN
                call    HERE
                call    SWAP
                jmp     STORE
              ; ret

;   AFT         ( a -- a A )
;               Jump to THEN in a FOR-AFT-THEN-NEXT loop the first time through.

                $CODE   IMEDD,'aft',AFT
                call    DROP
                call    AHEAD
                call    BEGIN
                jmp     SWAP
              ; ret

;   ELSE        ( A -- A )
;               Start the false clause in an IF-ELSE-THEN structure.

                $CODE   IMEDD,'else',ELSEE
                call    AHEAD
                call    SWAP
                jmp     THENN
              ; ret

;   WHILE       ( a -- A a )
;               Conditional branch out of a BEGIN-WHILE-REPEAT loop.

                $CODE   IMEDD,'while',WHILE
                call    IFF
                jmp     SWAP
              ; ret

;   ABORT"      ( -- ; <string> )
;               Conditional abort with an error message.

                $CODE   IMEDD,'abort"',ABRTQ
                call    COMPI
                call    ABORQ
                jmp     STRCQ
              ; ret

;   $"          ( -- ; <string> )
;               Compile an inline string literal.

                $CODE   IMEDD,'$"',STRQ
                call    COMPI
                call    STRQP
                jmp     STRCQ
              ; ret

;   ."          ( -- ; <string> )
;               Compile an inline string literal to be typed out at run time.

                $CODE   IMEDD,'."',DOTQ
                call    COMPI
                call    DOTQP
                jmp     STRCQ
              ; ret

;; Name compiler

;   ?UNIQUE     ( a -- a )
;               Display a warning message if the word already exists.

                $CODE   0,'?unique',UNIQU
                call    DUPP
                call    NAMEQ              ;?name exists
                $QBRAN UNIQ1
                call    DOTQP                   ;redefinitions are OK
                DB      7,' reDef '             ;but the user should be warned
                call    OVER
                call    COUNT
                call    TYPES        ;just in case its not planned
UNIQ1:          jmp     DROP
              ; ret

;   $,n         ( na -- )
;   $,n(orig)   Build a new dictionary name using the string at na.
;               na is a structure of [link]"counted string", link the sructure into
;               context and adjust HERE.

                $CODE   0,'$,n(orig)',SNAMEORIG
                call    DUPP      ; na na
                call    CAT       ; na len     ;?null input
                $QBRAN PNAM1      ; na
                call    UNIQU     ; na         ; ( a -- a ) ?redefinition  only display warning message
                call    DUPP      ; na na
                call    COUNT     ; na na+1 len
                call    PLUS      ; na na+1+len
                call    CP        ; na na+1+len CP
                call    STORE     ; na             ;skip here to after the name
                call    DUPP      ; na na
                call    LAST      ; na na last
                call    STORE     ; na             ;save na for vocabulary link
                call    CELLM     ; na-cell        ;link address �_�ǡA�o�]���� �h�[�@�I
                call    CNTXT     ; na-cell context
                call    ATT       ; na-cell context@
                call    SWAP      ; context@ na-cell
                jmp     STORE     ; empty          �s word �� link ���V�� context
              ; ret               ;                ;save code pointer
PNAM1:          call    STRQP     ;
                DB      5,' name' ;                ;null input
                $BRAN   ABOR1     ;

                $CODE   0,'$,n',SNAME
                call    TSNAME
                jmp     ATEXE


;; FORTH compiler

;   $COMPILE    ( a -- )
;               Compile next word to code dictionary as a token or literal.

                $CODE   0,'$compile',SCOMP
                CALL    NAMEQ
                CALL    QDUP              ;?defined
                $QBRAN  SCOM2
                CALL    ATT
                CALL    DOLIT
                DQ      IMEDD
                CALL    ANDD              ;?immediate
                $QBRAN  SCOM1
                jmp     EXECU
              ; ret                       ;its immediate, execute
        SCOM1:
                jmp     CALLC
              ; ret                       ;its not immediate, compile
        SCOM2:
                CALL    NUMBQ             ;try to convert to number
                $QBRAN  ABOR1
                jmp     LITER
              ; ret                       ;compile number as integer


; overt(orig)   ( -- )
;               Default overt. Add new words to 'context' because there's no 'current' yet.
;               Link a new word into the current vocabulary.
;               Overt ���r�N�O�u���}�v�C

                $CODE   0,'overt(orig)',OVERTORIG
                call    LAST
                call    ATT
                call    CNTXT
                jmp     STORE

;   OVERT       ( -- )
;               Link a new word into the current vocabulary.
;               Overt ���r�N�O�u���}�v�C

                $CODE   0,'overt',OVERT
                call    TOVERT
                jmp     ATEXE

;   ;           ( -- )
;   ;(orig)     Terminate a colon definition.

                $CODE   IMEDD+COMPO,';(orig)',SEMISORIG
                call    DOLIT
                DQ      RETT
                CALL    CCOMMA
                call    LBRAC
                jmp     OVERT

                $CODE   IMEDD+COMPO,';',SEMIS
                call    TSEMIS
                jmp     ATEXE

;   ]           ( -- )
;               Start compiling the words in the input stream.

                $CODE   0,']',RBRAC
                call    DOLIT
                DQ      SCOMP
                call    TEVAL
                jmp     STORE
              ; ret

;   call,       ( ca -- )
;               Assemble a call instruction to ca.

                $CODE   0,'call,',CALLC
                call    DOLIT
                DQ      CALLL         ; ca E8          'call' opcode is E8
                call    CCOMMA        ; ca
                call    HERE          ; ca here
                call    DOLIT
                DQ      CALLSIZE-1
                call    PLUS          ; ca here+CALLSIZE-1  offset has CALLSIZE-1 bytes
                call    SUBB          ; ca-(here+CALLSIZE-1)
                jmp     DCOMMA
              ; ret                   ;

;   :           ( -- ; <string> )
;               Start a new colon definition using next word as its name.

                $CODE   0,':',COLON
                call    TOKEN
                call    SNAME
                jmp     RBRAC
              ; ret

;   IMMEDIATE   ( -- )
;               Make the last compiled word an immediate word.

                $CODE   0,'immediate',IMMED
                call    DOLIT
                DQ      IMEDD
                call    LAST
                call    ATT
                call    ATT
                call    ORR
                call    LAST
                call    ATT
                jmp     STORE
              ; ret

;; Defining words

; create        ( -- ; <string> )
; create(orig)  Compile a new array entry without allocating code space.

                $CODE   0,'create(orig)',CREATORIG
                CALL    TOKEN
                CALL    SNAME
                CALL    OVERT
                CALL    COMPI
                call    DOVAR     ; �o�� call dovar , ret ����令 jmp dovar. �N�䤣�@�ˡI
                ret

                $CODE   0,'create',CREAT
                call    TCREATE
                jmp     ATEXE

;===============================================================
LASTN           EQU     _LINK+COLDD        ; last name address in name dictionary
CTOP            EQU     $                  ; next available memory in code dictionary. Reserve 512k for source code.
forthcode       EQU     $                  ; in-binary forth source code appended from here on.
;===============================================================
