
.(  including 01_basics_p1.f ) cr

// Assembler �����H�e�N�n���Ψ쪺 CPU instructions

                   : exit          $c3 c,                      ; immediate
                   : inc[rbx]      $48 c, $FF c, $03 c,        ; immediate \ inc   qword [rbx]
                   : dec[rbx]      $48 c, $FF c, $0B c,        ; immediate \ dec   qword [rbx]
                   : movsx.rbx,bl  $48 c, $0F c, $BE c, $DB c, ; immediate \ movsx rbx,bl
                   : movsx.rbx,bx  $48 c, $0F c, $BF c, $DB c, ; immediate \ movsx rbx,bx
                   : movsx.rbx,ebx $48 c, $63 c, $DB c,        ; immediate \ movsx rbx,ebx
                   : rbx+n8        $48 c, $83 c, $C3 c, c,     ; immediate \ add   rbx,n8
                   : rbx&n8        $48 c, $83 c, $E3 c, c,     ; immediate \ and   rbx,n8
                   : rbp+n8        $48 c, $83 c, $C5 c, c,     ; immediate \ add   rbp,n8

// �쪩��ʪ��򥻥\��  ANS Words

\  compile-only    ( -- )
\                  Make the last compiled word an compile-only word.
\                  Refer to eforth86.asm also weforth(fsharp)\F#221\HF0META.F
                   : compile-only
                     COMPO last @ @ or last @ ! ;  \ ���� 1 byte 8 bytes �ĪG�@��

\ char             ( -<char>- -- char )
\                  Interprete state. Get TIB next word's first char's ASCII

                   : char    bl word 1+ c@ ;

\ [char]           ( -<char>- -- char )
\                  Compile state. Get TIB next word's first char's ASCII

                   : [char]  char  [compile] literal ; immediate

\  [']             ( -<name>- -- ca )
\                  Search context vocabularies for the next word in colon definition.
\                  ���� eforth86.asm �̨S�� [']�H �]���b .asm �� ['] something �g�� DOLIT,something �Y�i�C

                   : ['] ' [compile] literal ; immediate

\  <=              ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 <= n2

                   : <=
                     -         \ n1-n2   �쪩�u�� < �i��
                     1 <       \ (n1-n2) < 1 ��ܭt�Ʃιs n1<=n2
                   ;

\  >               ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 > n2

                   : > <= not ;

\  >=              ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 >= n2

                   : >= < not ;

\  <>              ( n1 n2 -- t )
\                  Compare of top two items. True if n1 <> n2

                   : <> = not ;

\  0=              ( n -- t )
\                  Logical NOT, if n==0 then True(-1) else if n!=0 then False(0)
\                  �p�ߡI 'not' ���O�O bitwise �� 1's complement, �۷�� C language �� ~ operator.
\                  �n�� boolean ���u�O/�D �A�ˡv, �۷�� C Language �� �I operator, �Х� 0= �C

                   : 0= 0 = ;

\  -rot            ( 1 2 3 -- 3 1 2 )
\                  Rotate 3 cells

                   : -rot rot rot ;

\  nip             ( 1 2 -- 2 )
\                  Drop the previous cell in data stack.

                   : nip   [ 8 ] rbp+n8 ;

\  VARIABLE        ( -- ; <string> )
\                  Compile a new variable initialized to 0.

                   : variable  create 0 , ;

\ end-word         ( -- )
\                  word �쥻�� data structure �O [LFA][NFA][CFA][BODY], �s�W [VFA] ���V���ݪ� vocabulary wordlist,
\                  [EFA] ���V�� word ���᪺��}�A�Ӧ��� [VFA][EFA][LFA][NFA][CFA][BODY]�C
\                  ���ӥ���� overt �Ӷ�g EFA VFA, �[��쪩 eforth86 �̥u���T�ӤH�|�Ψ� overt: COLD �O�� overt
\                  �ӵ� context �����; Semicolon �P colon �۹�Ψӧ�s�r��i context; create �h�O���W��s word
\                  ��i context, �䤤�u�� semicolon �� overt �O��g EFA ���n�ɾ��C�ҥH���� overt �ӥt�зs word�C
\                  ���Z�@�I�N�s end-word�A ���I end-code ���p�Q�C
\                  last @ 1 cells -  LFA
\                  last @ 2 cells -  EFA  = here
\                  last @ 3 cells -  VFA  = current@

                   create 'end-word ' noop ,  \ �@�}�l do nothing.
                   
                   : end-word 
                       'end-word @execute 
                   ;

\
\  does>           hcchen5600 2011/11/15 11:14:09 �� STC �g���s�� DOES> �~�|��N�����F�A�o���Ӻ�ܦn�F�C
\                  ���I�O�� create ���ͪ��Ĥ@�� call doVAR �令 call DOES> �᭱�� words�A�p���Ӥw�C�� call ���
\                  �O jump �s�a���o PFA�C
\                  ���O see "2011/11/15 10:32  eforth64 STC Create - Does> design" or evernote:///view/2472143/s22/aa0f776e-7de5-4c88-9dff-66817c95ff0d/aa0f776e-7de5-4c88-9dff-66817c95ff0d/
\                  �p�� PFA �n�h�Τ@�� r> �Ө��o�A�o�O�ӯ��I�٬O�u�I�H��ı�o�O�u�I�A�����u�ʡC

                   : does>
                       end-word          \ �� last word �إ� VFA EFA.
                       last @ name>      \ cfa
                       r>                \ cfa doesEntry   C time code entry point of the create-does class
                       over callsize+ -  \ cfa (doesEntry-(cfa+5))
                       swap 1+ d!        \ (doesEntry-(cfa+5)) cfa+1 => empty
                   ;

\  constant        ( -- )
\                  reate a constant.
\                  From Forth\eforth\weforth(fsharp)\weforth240\cmdline\0STDIO.F

                   : constant
                     create ,
                     does> r> @
                   ;

\  align           ( -- )
\                  Adjust here to next 8 bytes aligned address.

                   : aligned ( a -- a' ) ( 6.1.0706 ) \ align a to 8 bytes boundary a'
                       [  7 ] rbx+n8    \ a = a + (align distance - 1)  \ very good, copy from Win32Forth
                       [ -8 ] rbx&n8    \ a |= -(align distance)
                   ;

                   : align ( -- ) ( 6.1.0705 ) here aligned cp ! ;

\ recurse          ( -- )   6.1.2120
\                  Append the execution semantics of the current definition
\                  to the current definition.

                   : recurse  last @ name> call,  ; immediate

\ >xt              ( cfa -- xt )
\                  STC call or jump instructions are with a related target address.
\                  xt is an execution address, another CFA. When cfa points to a call 
\                  instruction, the related address needs translation.

                   : >xt   ( cfa -- xt )  
                         dup 1+          \ cfa addr+1
                         d@              \ cfa related_address_4bytes
                         movsx.rbx,ebx   \ cfa related_address            sign bit extension �� 64 bits
                         swap            \ related_address cfa
                         callsize+       \ related_address cfa+callsize
                         +               \ xt 
                   ;

\ hcchen5600 2011/12/26 00:36:51 [x] �Q�� defer �ӧ� >name ���� deferred word �a�I
\ ����I defer �|�Ψ� >name. ��F�C >name �٤���� defer�C


\   >NAME          ( ca -- na | F )
\                  Convert code address to a name address.

                   variable '>name
                   : >name(orig)
                       context
                       begin
                         @ dup
                       while
                         2dup name> xor
                         if
                           cell-
                         else
                           swap drop
                           [ $c3 c, ]  \ ret instruction
                         then
                       repeat
                       2drop 0
                   ;
                   ' >name(orig) '>name !    \ �N�� vocabulary ���n�F�H��n����

                   : >name
                       '>name @execute
                   ;

\  defer           ( -- )
\                  defer is a class. Generate deferred word objects.
\                  Proptety is entry point. Method is to execute the entry point.

                   : >body ( cfa -- body )  callsize+ ; \ skip the call instruction at cfa to the next address which is the property of an object, for example.
                   : compiling ( -- yes ) 'eval @ ['] $interpret - ;  \ is compiling mode? Check whether if 'eval == $interpret.
                   : defer
                       create
                         ['] noop ,     \ ���o�o�� property ��}����k�O ' defer.word.name >body �Y�i�C
                       does>
                         [ here ]
                         r> @execute
                   ;

                   constant dodefer     \ �O�� defer.method ����}�C
                   variable (is)
                   defer is immediate  \ is �@�}�l��M�O noop

                   \ �ھ� defer ���w�q�Asee is �ݨ쪺�O�G
                   \     call defer.does>
                   \     DQ noop
                   \ �U����Ū _is_ �ɭn�Ψ�Chcchen5600 2011/12/17 18:14:26

                   : (_is_) ( n -- )  \ �ڲq�A�o�ӬO is �� compiling state ��
                       r>             \ n a         a �^���}�C
                       >body          \ n a+5       �^���}�W�O call something, �A�U�@�Ӧ�}...�O����H�C
                       dup            \ n a+5 a+5
                       >r ( n a )     \ n a+5 [a+5] �w�Ʀn�s�� return address
                       dup            \ n a+5 a+5
                       @              \ n a+5 (a+5)
                       +              \ n a+5+(a+5)
                       cell+ ( n ca ) \ n a+5+(a+5)+cell
                       >body ( n pa ) \ n a+5+(a+5)+cell+cell
                       !              \ empty
                       ; \ refined later for more effesion

                   ' (_is_) (is) !    \ compiling state ���� is �O�i�H�⴫��

                   : _is_ ( interpret: ca <valuename> -- ) ( compiling: <valuename> -- )
                     '                  \ ( v ca )  tick ���o�᭱���� deferred word �� cfa , v is vector �Y�u�����i�J�I
                     dup >body          \ ( v ca pa ) �o�� pa �N�O�᭱�o�� deferred word �� property
                     dup                \ ( v ca pa pa )
                     4 -                \ ( v ca pa pa-4 )���Ӽg�� cell- �o�O�a�ߺD�C���令 4 - �٬O����A�ӬݤU�h�C �C �C
                     d@                 \ ( v ca pa d@(pa-4) )  ���r @ �]����A�n�令 d@ �o�N���n�d�ǤH�F�I
                     movsx.rbx,ebx      \ ( v ca pa d@(pa-4) )  �o�ӧ�F�` sign bit extension �e�H����Q����CBits ���ܯu�O�·Э��I
                     +                  \ ( v ca ca' )    �� call ���۹��}���⦨ linear address
                     dodefer xor        \ ( v ca flag )  ���b�ˬd�A�T�w is �᭱�o�� word �O�� defrred word ����k�N�O�ݥ��O�_ call defer.does> �o�I����S���C
                     over c@ $e8 xor or \ ( v ca flag' )
                     if                 \ ( v ca )
                       cr ." can't put ca into non-defer word "
                       >name count $1F and type
                       abort
                     then               ( v ca )
                     compiling if
                       (is) @ call, call,
                     else
                       >body !
                     then
                   ; immediate

                   ' _is_  _is_ is      \ is ���W�Φb�ۤv���W�I

\  alias           ( CFA <name> -- )   [x] �令 STC ����A���I�i�áAwhite box test needed.
\                  CFA �O code field address, �Y�@ word ���i�J�I�A�� tick ' ���o�C
\                  �Ҧp�G ' *debug* alias *bp* �N�O���ͤ@�ӦW�� *bp* ���s word �@�λP *debug* �ۦP�C

                   : alias
                       bl word $,n overt
                       $e9 c, dup                 \ ca ca  where $e9 is "jmp a32"
                       here callsize+ 1- - d,     \ ca ca-(here+4)
                       >name c@ IMEDD and
                       if immediate
                       then
                   ;

                   ' \(orig) alias \s                 \ \s is the official stop compiling marker

\  ?exit           ( boolean -- )
\                  Exit this word. Make sure r@ is this word's return address in prior, that
\                  is to balance the return stack first.

                   : ?exit
                       if
                         r> drop  \ �o�� return address �O�� word �ۤv���A�Q�ᱼ�H��
                       then       \ �� word �� exit �N�ܦ��h��� caller �� return address.
                   ;              \ �]�����͵����� word ���ĪG�C��M return stack �n�� balance�C

\  .q 64 bits      ( data -- )
\  .d 32 bits      Print given number in hexdecimal format with leading 0's
\  .w word
\  .b byte

                   : .b                     \ n
                       base @ >r hex        \ n [base]
                       <# # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .w                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .d                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # # # # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .q                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # # # # # # # # # # # # # #> type
                       r> base !            \ empty [empty]
                   ;

// %%%%%%%%%%%%%%%%%%%% Vocbulary words from Bill Muench's bforth %%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ �޶i vocabulary ����A last �S�ܡA���O context ���N�q�ܤF�C���ӻP last �ʽ�۪�A�ܦ��h��@���ܦ����Ӫ� pointer�C
\ Was   : Last @ == context @ == Address of last word's counted string name field [length]'name string' (NFA).
\ To be : Last @ == context @ @ == Forth.wordptr @ == NFA
\ context @ == forth.NFA <================ �Ҧ��Ψ� context ���a�賣�n��
\
\                 wid wordlist             wid wordlist                       wid wordlist
\   context @ --->.--------------.         .--------------.                   .--------------.
\   current @ --->| NFA          |--.  .-->| NFA          |--.  .--> . . . -->|  NULL        |
\   vocs-head --->'--------------'  |  |   '--------------'  |  |             '--------------'
\                 | linkage      |--|--'   | linkage      |--|--'             |  NULL        |
\                 '--------------'  |      '--------------'  |                '--------------'
\                 | nfa voc-name |  |      | nfa voc-name |--|-----.          |  NULL        |
\                 '--------------'  |      '--------------'  |     |          '--------------'
\                                   |                        |     |
\                 .--------------.  |      .--------------.  |     |      FORTH or Assembler one of other vocabularies
\             .---| linkage      |  |  .---| linkage      |  |     |      .--------------.
\             |   '--------------'  |  |   '--------------'  |     |      | LFA          |
\             |   | nfa          |<-'  |   | nfa          |<-'     |      .------.-------'--.
\             |   '--------------'     |   '--------------'        '----> |length| name     |
\             |   | cfa          |     |   | cfa          |               '------'----------'
\             |   '--------------'     |   '--------------'               | call >voc.does> |
\             |                        |                                  '-----------------'
\             |   .--------------.     |   .--------------.               | ptr to wordlist |-----> �W�� wid wordlist �����@�ӡC
\             |   | linkage      |--.  |   | linkage      |--.            '-----------------'
\             |   '--------------'  |  |   '--------------'  |
\             '-->| nfa          |  |  '-->| nfa          |  |
\                 '--------------'  |      '--------------'  |
\                 | cfa          |  |      | cfa          |  |
\                 '--------------'  |      '--------------'  |
\                                   .                        .
\                                   .                        .
\                                   .                        .
\                 .--------------.  |
\                 | NULL         |  |
\                 '--------------'  |
\                 | nfa          |<-'
\                 '--------------'
\                 | cfa          |
\                 '--------------'
\
\
\  vocs-search-list
\                 .--------------.--------------.          .--------------------------.
\                 | 'wid 0       | 'wid 1       | . . . .  | 'wid #vocs-order-list    |
\                 '--------------'--------------'          '--------------------------'
\
\
\  vocabulary Forth                         vocabulary assembler                     vocabulary ISR
\  ----------------                         --------------------                     --------------------
\
\  FORTH               �W�� wid wordlist    Assembler           �W�� wid wordlist    ISR                 �W�� wid wordlist
\  .--------------.    �����@�ӡC           .--------------.    �����@�ӡC           .--------------.    �����@�ӡC
\  | LFA          |        ^                | LFA          |        ^                | LFA          |        ^
\  .------.-------'--.     |                .------.-------'--.     |                .------.-------'--.     |
\  |length| name     |     |                |length| name     |     |                |length| name     |     |
\  '------'----------'     |                '------'----------'     |                '------'----------'     |
\  | call >voc.does> |     |                | call >voc.does> |     |                | call >voc.does> |     |
\  '-----------------'     |                '-----------------'     |                '-----------------'     |
\  | ptr to wordlist |-----'                | ptr to wordlist |-----'                | ptr to wordlist |-----'
\  '-----------------'                      '-----------------'                      '-----------------'
\
\  method >voc.does> is to re-arrange the order so as to add this wordlist to the top of the order.
\

\  .id             ( na -- )
\                  Display the name at address.

                   : .id
                       ?dup if
                         count $1F and
                         type exit
                       then
                       ." {noName}"
                   ;

    16 constant #vocs-order-list ( search order list )
    create vocs-order-list #vocs-order-list 1+ cells allot ( wids ) vocs-order-list here over - erase \ one more reservation for end of array ending NULL
    create forth-wordlist ( -- wid ) ( 16.6.1.1595 )  \ FORTH �� instance ����C
        0 , ( na, of last definition, linked )
        0 , ( wid|0, next or last wordlist in chain )
        0 , ( na, wordlist name pointer )

    create current   ( -- wid )
        forth-wordlist ,      \ new word add to this wordlist

    create vocs-head ( -- wid )
        forth-wordlist ,      \ head of chain �Y�Ҧ� forth ���Y��C

  \ create context(vocs) ( -- wid ) forth-wordlist ,   \ ������ context �ܩʡA���ݥt�~ create �s�F��C
    : get-current ( -- wid ) ( 16.6.1.1643 ) current @ ;
    : set-current ( wid -- ) ( 16.6.1.2195 ) current ! ;
    : definitions ( -- ) ( 16.6.1.1180 ) context @ set-current ;

    : >wid ( wid -- ) cell+ ; \ next wid

    : .wid ( wid -- )       \ print wid name or address
        space               \ wid
        dup                 \ wid wid
        2 cells +           \ wid wid+2cells
        @                   \ wid (wid+2cells)
        ?dup                \ wid [(wid+2cells) (wid+2cells)|0]
        if                  \ wid (wid+2cells)
          .id               \ wid               print (wid+2cells)
          drop              \ empty
          exit              \
        then                \ wid
        0                   \ wid 0
        u.r                 \                   print wid if no name yet
    ;

    : !wid ( wid -- )       \ wid[2] = nfa of last word which is this wordlist's name
        2 cells +           \ wid[2]
        last @              \ wid[2] nfa
        swap                \ nfa wid[2]       wid+2cells = last word's nfa
        !                   \ empty
    ;

    : vocs ( -- ) ( list all wordlists )
        cr ." vocs:" vocs-head
        begin              \ a          head of chain
          @                \ wid
          ?dup             \ (wid wid)|0
        while              \ wid
          dup              \ wid wid
          .wid             \ wid        print wid or print .id(wid+2cells)
          >wid             \ wid+cell   �Ҧ��� wordlist �O��_�Ӫ��A�ҥH�Ӽƥi�H���w�ڡI#vocs �O���ܼơC
        repeat             \ a'
    ;

    : wordlist ( -- wid ) ( 16.6.1.2460 )   \ generate a wid structure  \ [ 0 , pointer to previous wid, 0 ]
        align               \ empty                                     \   ^
        here                \ a                                         \   |
        0 ,                 \ a                   compile 0             \   |
        dup                 \ a a                                       \   |
        vocs-head           \ a a (head of wordlist chain)              \   '---------- head of chain vocs-head
        dup                 \ a a chain chain
        @ ,                 \ a a chain           compile first wid of the chain
        !                   \ a                   assign this wid to head of chain
        0 , ;               \ a                   compile 0

    : order@ ( a -- u*wid u )       \ a is context or other forth-wordlist head
        dup                         \ a a
        @                           \ a nfa
        dup                         \ a nfa nfa
        if                          \ a nfa
          >r                        \ a       [nfa]
            cell+                   \ a+cell
            recurse                 \          run this word recursively
          r>                        \ 'nfa 'nfa@==0 head-nfa
          swap 1+                   \ 'nfa head-nfa 'nfa@==0
          exit
        then                        \ a nfa==0
        nip ;                       \

    : get-order ( -- u*wid u ) ( 16.6.1.1647 ) vocs-order-list ( context ) order@ ;
                ( -- widu ... wid2 wid1 u )

    defer sync-context
    : do-sync-context vocs-order-list @ context ! ; \ first item copy to context
    
    : set-order ( u*wid n -- ) ( 16.6.1.2197 )
        dup                         \ widu ... wid2 wid1 u u
        -1 = if                     \ -1
          drop                      \ empty
          forth-wordlist            \ forth           ( 16.6.1.1595 )
          1                         \ forth 1
        then ( default ? )          \ [widu ... wid2 wid1 u] or [forth 1]
        [ #vocs-order-list ]        \ [widu ... wid2 wid1 u] or [forth 1] #vocs=8  �p�G #vocs �O�� constant �o��������²��g�@�� #vocs [ ]�ոլݡC
        literal                     \ [widu ... wid2 wid1 u] or [forth 1] 8    \ compile 8 into dictionary
        over                        \ widu ... wid2 wid1 u #vocs u
        u<                          \ widu ... wid2 wid1 u #vocs<u   ���b�I���n�C
        abort" Over size of #vocs-order-list"
        vocs-order-list             \ widu ... wid2 wid1 u VOL
        swap                        \ widu ... wid2 wid1 VOL u
        begin                       \ widu ... wid2 wid1 VOL u
          dup                       \ widu ... wid2 wid1 VOL u u
        while                       \ widu ... wid2 wid1 VOL u
          >r                        \ widu ... wid2 wid1 VOL         [ u ]
          swap                      \ widu ... wid2 VOL wid1
          over                      \ widu ... wid2 VOL wid1 VOL
          !                         \ widu ... wid2 VOL              VOL=wid1
          cell+                     \ widu ... wid2 VOL+cell
          r>                        \ widu ... wid2 VOL+cell n
          1-                        \ widu ... wid2 VOL+cell n-1
        repeat  ( 0 )               \ widu ... wid2 VOL+cell n-1
        swap !                      \ VOL+cell 0 ==>  0 VOL+cell ==> VOL+cell = null end of the list. �ҥH #vocs ���M�O 8 allot �ɭn�[�@��C
        sync-context                \ first order item copy to context. ���@�����m����~�}�l���A�G�� deferred word. 
    ;

    : order ( -- ) ( list search order )
        cr ." search:"
        get-order    \ widn ... wid2 wid1 n
        begin        \ widn ... wid2 wid1 n
           ?dup      \ widn ... wid2 wid1 n n
        while        \ widn ... wid2 wid1 n
           swap      \ widn ... wid2 n wid1
           .wid      \ widn ... wid2 n
           1 -       \ widn ... wid2 n-1
        repeat       \ empty
        cr ." define:"
        get-current  \ wid
        .wid ;       \ empty

    : only ( -- ) -1 set-order ;
    : also ( -- )    \ Also �N�O vocabulary array �� dup
        get-order    \ widn ... wid2 wid1 n
        over         \ widn ... wid2 wid1 n wid1
        swap         \ widn ... wid2 wid1 wid1 n
        1 +          \ widn ... wid2 wid1 wid1 n+1
        set-order
    ;

    : previous ( -- )   \ previous �N�O  vocabulary array �� drop
        get-order    \ widn ... wid2 wid1 n
        swap         \ widn ... wid2 n wid1
        drop         \ widn ... wid2 n
        1 -          \ widn ... wid2 n-1
        set-order
    ;

    : >voc ( wid 'name' -- )  \ vocabulary-creater class. forth editor �����O�γo�� create �X�Ӫ��C
        create
          dup      \ wid wid
          ,        \ wid
          !wid     \ wid[2]=the last word name
        does>
          r>
          @        \ wid
          >r          \ empty      [wid]
          get-order   \ widn ... wid2 wid1 n
          swap        \ widn ... wid2 n wid1
          drop        \ widn ... wid2 n
          r>          \ widn ... wid2 n wid [empty]
          swap        \ widn ... wid2 wid n
          set-order
    ;

    : vocabulary ( 'name' -- )
        wordlist \ generate a wid structure
        >voc     \ create a vocabulary name for the given wid structure
    ;

\ hcchen5600 2011/12/21 09:17:03 context ���ӬO���V last @ �P�˪��a��A�̫�@ word �� NFA�C�{�b
\ �n��h�@�B�A�令���V�Y�@�� wordlist, FORTH HIDDEN .. etc, �M��A�� wordlist ���V�� wordlist
\ ���̷s word's NFA�C�p���@�ӡA�Ҧ��Ψ� context ���H�����n��I�L��n�o�k�A����n�Ҧ��Ψ� context
\ �� words �L�̥������ context(vocs). �]�� context(vocs) �M context �̲פ@�˳��O���V wordlist
\ �ҥH�u�n�� vocabulary FORTH �w�Ʀn�A�N�i�H����o�Ƿs�� words, ���S���D����A���쪩�� words �H
\ �� context ���ܦ��s���� alias �Y�i�C

\ These words uses context : context >name words nextword $,n <overt> name?
\ Change them to (vocs) version : >name(vocs) words(vocs) nextword(vocs) $,n(vocs) <overt>(vocs) name?(vocs)
\ context �������ΥX�s word context(vocs) �u�n�u�έ� word �������a vocs ���s�ʽ�Y�i�C

\ ��g�o�ǭ�ӥ� context �� words �n���@�ƭȪ� context �X�R�� get-order �ұo�쪺�ƦC�C�o�Ӱʧ@�i�H��
\ order �̪��g�k�C�L�Τ@�� begin-while-repeat �N�ѨM�F�C

\   name?          ( a -- ca na | a F )
\   name?(vocs)    Search all context vocabularies for a string.

                   : name?(vocs)
                       >r           \ [ a ]
                       get-order    \ widn ... wid2 wid1 n
                       begin        \ widn ... wid2 wid1 n
                          ?dup      \ widn ... wid2 wid1 n n
                       while        \ widn ... wid2 wid1 n
                          swap      \ widn ... wid2 n wid1
                        \ ----------------------------------
                          r@ swap   \ ... a wid
                          find      \ ... (ca na)|(a F)
                          ?dup      \ ... (ca na na)|(a F)
                          if        \ ... (ca na)|(a)  \ found
                            >r >r   \ widn ... wid2 n [ca na a]
                            1- for aft drop then next  \ clear rest of the order-list
                            r> r> r> drop              \ ca na
                            exit                       \ ca na
                          else                         \ not found in this wordlist
                            drop    \ ...
                          then
                        \ ----------------------------------
                          1 -       \ widn ... wid2 n-1
                       repeat       \ empty
                       r> 0         \ a 0       balance return stack
                   ;

                   \ ���\�F�I �����k�G���˥X�� counted string : name $" see" ; ���`�Ϊk name name? �N�i
                   \ �H�Ǧ^ see �� cfa nfa. �{�b�� name ���� name?(vocs) �]�Ǧ^���T��, Bingo! �h�˴X��
                   \ wordlist: vocabulary assembler vocabulary isr <=== �˥X��� wordlist
                   \ also assembler also isr <========= ��i wordlist order list
                   \ name name?(vocs) �٬O�@�˥��T�Ǧ^ see �� cfa nfa .... ���\�I

\ end-word         ( -- )
\                  word �쥻�� data structure �O [LFA][NFA][CFA][BODY], �s�W [VFA] ���V���ݪ� vocabulary wordlist,
\                  [EFA] ���V�� word ���᪺��}�A�Ӧ��� [VFA][EFA][LFA][NFA][CFA][BODY]�C
\                  ���ӥ���� overt �Ӷ�g EFA VFA, �[��쪩 eforth86 �̥u���T�ӤH�|�Ψ� overt: COLD �O�� overt �ӵ�
\                  context �����; Semicolon �P colon �۹�Ψӧ�s�r��i context; create �h�O���W��s word ��i context,
\                  �䤤�u�� semicolon �� overt �O��g EFA ���n�ɾ��C�ҥH���� overt �ӥt�зs word�C
\                  ���Z�@�I�N�s end-word�A ���I end-code ���p�Q�C
\                  last @ 1 cells -  LFA
\                  last @ 2 cells -  EFA  = here
\                  last @ 3 cells -  VFA  = current@

                   : end-word(vocs) ( -- )    \ write here to EFA, current@ to VFA of the last word.
                       current @        \ current@       current active vocabulary
                       last @ 2 cells - \ current@ EFA
                       here over        \ current@ EFA here EFA
                       ! cell-          \ current@ VFA
                       !                \ empty
                   ;

\   <overt>        ( -- )
\   overt(vocs)    Default overt. Add new words to 'context' because there's no 'current' yet.
\                  Link a new word into the current vocabulary.
\                  Overt ���r�N�O�u���}�v�C

                   : overt(vocs)
                       last @ current @ ! \ ���ӬO context ! �令 current @ ! �h�����@�h�Ccurrent@ ���V�Y�� wordlist. current@@ = wordlist[0] �~�O NFA�C
                   ;

                   \ �����k�G�˭ӷs vocabulary aux�Aalso aux definitions
                   \ �[�s�r���� overt(vocs) �@�U�A�u current trace �ݬݡC
                   \ current = 11F2D4  �o�O current �ۤv�� property �a�}
                   \ current@ = 11F880 �o�O wordlist �a�}�A�@�}�l current@@ = 11F880@ = NULL.
                   \ overt(vocs) ����A�G�M current@@ ���V�F�s word �� NFA �L�~�C

\   ;              ( -- )
\                  Terminate a colon definition.
\   ;(vocs)        ���F end-word ����A semicolon �]�n�X�s���C

                   : ;(vocs)
                       RETT c, [compile] [ overt(vocs) end-word
                   ;  immediate compile-only

                   \ �쪩 ; decompiled �X�ӬݬO:
                   \    call dolit
                   \    DQ C3
                   \    call c,
                   \    call [
                   \    jmp  overt
                   \ Its forth source should be ": ; $c3 c, [compile] [ overt ;". Where [ is immediate
                   \ therefore we need the leading [compile] to make it compiled here.


\ create           ( -- ; <string> )
\ create(vocs)     ���F end-word ����A create �]�n�X�s���C

                   : create(vocs)
                       create(orig)
                       end-word
                   ;    

\   $,n            ( na -- )
\   $,n(vocs)      Build a new dictionary name using the string at na.
\                  na is a structure of [link]"counted string", link the sructure into
\                  current vocabulary and adjust HERE.

                   : $,n(vocs)
                       dup               \ na na
                       c@                \ na len     ; ?null input
                       0= abort" name"   \ na
                       ?unique           \ na         ; ( a -- a ) ?redefinition  only display warning message
                       dup               \ na na
                       count             \ na na+1 len
                       +                 \ na na+1+len
                       cp                \ na na+1+len CP
                       !                 \ na             ;skip here to after the name
                       dup               \ na na
                       last              \ na na last
                       !                 \ na             ;save na for vocabulary link
                       cell-             \ na-cell        ;link address
                       current           \ na-cell current
                       @ @               \ na-cell current@@    ;get last word's NFA
                       swap              \ current@@ na-cell    ;this link points to last word's NFA
                       !                 \ empty          ;�s word �� link ���V�� current
                   ;                     \ �� current ��򤣽վ�H���I���O overt ���u�@�C

                   \ How to test? $,n always works after 'token'. While 'token' returns a counted string
                   \ from user. The counted string is after a cell and the cell is at here. So 'token'
                   \ makes here a structure like this : [link]'word' and '$,n' links this new name to both
                   \ last and current@. Current@@ is still old value, it's adjusted by overt later.
                   \ So, test method is ... : test$,n(vocs) token $,n(vocs) overt(vocs) ; This is to create
                   \ a new name. The new name appears on current list. Check it out.

                   \ �����k�G�˭ӷs vocabulary aux�Aalso aux definitions
                   \ �[�s�r���� overt(vocs) �@�U�A�u current trace �ݬݡC
                   \ current = 11F2D4  �o�O current �ۤv�� property �a�}
                   \ current@ = 11F880 �o�O wordlist �a�}�A�@�}�l current@@ = 11F880@ = NULL.
                   \ overt(vocs) ����A�G�M current@@ ���V�F�s word �� NFA �L�~�C

                   \ vocabulary aux also aux definitions
                   \ : anw token $,n(vocs) overt(vocs) ; \ add new word , for test
                   \ anw new-word anw new1111 anw new22222
                   \ ���� current @ @ d \ �G�M�N�O new-word �� NFA.

\   >NAME          ( ca -- na | F )
\   >name(vocs)    Convert code address to a name address.
\                  �n�� cfa �ন nfa �٤�²��H���O�n�T�w�o�� cfa �O�_�s�b��ثe vocabulary list �̴N�o�q�Y
\                  ��@�M�~�൴��T�w�C �Y�ϳo�� cfa �T��s�b�A��e order �̧䤣��]�n�^ false�C

                   \ �쪩�h���Ĥ@��Y�ܦ��������w wordlist (or vocabulary or wid all samething) ����¦��
                   : (>name)  ( ca va -- na | F )
                       begin                 \ ca wid    va �Y wid �۷�� context, wid@ �۷� context@ �Y�Ĥ@�� LFA
                         @ dup               \ ca nfa' nfa'
                       while                 \ ca nfa'
                         2dup name> xor      \ ca nfa' ca^cfa'
                         if                  \ ca nfa'
                           cell-             \ ca nfa'-cell    that's lfa. If this LFA@ is NULL then while loop terminated
                         else                \ ca nfa'
                           nip               \ nfa'
                           exit              \ ret instruction
                         then                \ ca lfa
                       repeat                \ ca lfa
                       2drop 0               \ 0
                   ;

                   : >name(vocs) ( ca -- na | F )
                       >r           \ [ ca ]
                       get-order    \ widn ... wid2 wid1 n
                       begin        \ widn ... wid2 wid1 n
                          ?dup      \ widn ... wid2 wid1 n n
                       while        \ widn ... wid2 wid1 n
                          swap      \ widn ... wid2 n wid1
                        \ ----------------------------------
                          r@ swap   \ ... ca va
                          (>name)   \ ... (na | F)   �p�G�����N�i�H�����A�_�h�n�դU�@�� vocabulary
                          ?dup if   \ na
                            >r      \ widn ... wid2 n [ca na] ���O�d���G�A�ǳƭn��ѤU�Ӫ� order list ���ᱼ
                            1- for aft drop then next  \ clear rest of the order-list
                            r> r> drop                 \ na
                            exit
                          then
                        \ ----------------------------------
                          1-        \ widn ... wid2 n-1
                       repeat       \ empty
                       r> drop 0    \ Not found, return F.
                   ;

                   \ ���աG ' aux callsize+ @ @ d �Y�i�ݨ� aux wordlist ���U���X�� dummy words, which is started
                   \ from the last NFA. Right after the NFA is CFA. Feed the CFA to >name(vocs) got the NFA back
                   \ correctly. Bingo! Try again ' + >name(vocs) got its NFA correctly also. Double bingo!!

\ �޶i vocabulary ����A�s�ؤ@�ܼ� vocs.threshold �O���̫�@���ഫ�e�� NFA�A�ΨӨ��N�쥻 nextword �̩ҥΪ� context�C
\ ����]�Sԣ nextword �i���F�A�ڥ������D nextword �b���̡I �s words �u���D�ۤv�� EFA �Ϊu vocs.threshold ���� words
\ �� newer next word's LFA. �κ٬� EFA ����X�z�C

\ [x] forth-wordlist[0] should be pointing to the last word's NFA. But when to
\     do this? Should be when right before changing (orig) words to (vocs)
\     version.  ������e�A�]�n�H�K�˭ӭȵ� forth-wordlist[0] or the context wordlist.

                   forth-wordlist >voc forth
                   only forth \ �o�ӭn�����A�_�h get-order �u�Ǧ^ 0, ���઱�O�� vocabulary words . . .

                   : enable-vocabulary
                       [']      name?(vocs) 'name?    !
                       [']          ;(vocs) ';        !
                       [']        $,n(vocs) '$,n      !
                       [']      >name(vocs) '>name    !
                       [']      overt(vocs) 'overt    !
                       [']     create(vocs) 'create   !
                       [']   end-word(vocs) 'end-word !
                       last @          forth-wordlist !
                       forth-wordlist  context        !
                   ;

                   enable-vocabulary
                   ' do-sync-context is sync-context \ set-order �}�l sync context
                   only forth definitions \ �ΤW�F definitions �o�^�s current �����w���

\ vocs.threshold   ( -- a )
\                  equals to the recent context.
\                  vocs �����e�̫�@�� none-vocs word �N�O vocs.threshold �ۤv�C

                   here cell+ create vocs.threshold ,

                   \ ����G context @ �P vocs.threshold @ �۵��C
                   \ Variable vocs.threshold @ ���b�ۤv�� name NFA �W�C�ҥH vocs.threshold �S�p newer next word's LFA.
                   \ vocs.threshold @ cell- �O vocs.threshold �ۤv�� LFA, ���V�e�@ word �� NFA.
                   \ vocs.threshold @ cell- @ d �ݱo�즹�B���O�e�@�� word �� NFA.

\ hcchen5600 2011/12/23 20:43:03 Study ��ӥΨ� "token $,n" ���B�A�]�N�O colon : �H�� create, �b [link]'string'
\ ���e�h��X�� field �ܦ� [VFA][EFA][LFA]'string'. �쪩 eforth �� word �\�઺�T�� Bill Muench �h reserved
\ �F�@�ӫe�ɪ� 8 bytes �]�N�O���� [LFA], Bee forth �S�����ӡCeforth �� word ��H�a�h�O�d�@ cell �O����]���A��
\ �o�򰵯u�����n��A�o�򰵤]���⦳���D�A�ϦӬO�̦n����k�C�n�諸�O word �̭��O�d cell �ƭn���������C

                   3 cells reserve-word-fields !
                   \ �q���C�� word ���h�X�� cells �� LFA ���e�C�o�n�b vocabulary.f �̲Ĥ@�Ӱ��C

\ Allocate all official vocabularies 

                   vocabulary hidden
                   vocabulary disassembler
                   vocabulary assembler
                   vocabulary console
                   vocabulary debug
                   vocabulary isr
                   vocabulary mywords
                   
                   only forth 
                   also hidden 
                   also disassembler 
                   also assembler 
                   also isr 
                   also console 
                   also debug 
                   also mywords
                   also \ dummy slot for following definitions



