
.(  including 015_disasm_p1.f ) cr

// Disassembler

disassembler definitions

\   === PFA data structure ===
\   pfa(0):         0 ,  \ linkage
\   pfa(1):     entry ,  \ disassembler entry point
\   pfa(2):         1 ,  \ op-code size
\   pfa(3):    ( 8c ) ,  \ 8c op-code  
\   pfa(4): last @ 1+ ,  \ mnemonic
\   pfa(5)          0 ,  \ dirty count
\   pfa(6)          1 ,  \ parameter section  1 means 8#
\   pfa(7):         2 ,  \ parameter section  2 means 16#
\   pfa(n):         0 ,  \ parameter section  0 menas end of parameters

\  $iEval          ( string -- )
\                  Interpreter state $eval. Interprete a given counted string.
\                  You need this word when writing assembly macros instead of subroutines. Words are subroutines in STC.
\                  We don't need a $cEval for $compile mode, because it's been $compile mode when in colon definitions.


                   : $iEval                      \ string
                       'eval @  >r               \ string [state]
                       ['] $interpret 'eval !    \ string [state]   'eval=interpreter state
                       count $eval               \        [state]
                       r> 'eval !                \ empty            restore original state to 'eval
                   ;

                   : isJmp?     ( cfa -- Yes )  c@ JMPP  = ;

                   : isCall?    ( cfa -- Yes )  c@ CALLL = ;

                   : isRet?     ( cfa -- Yes )  c@ RETT = ;

\ ���F�q assembler .asm �ɪ��� copy binary code �L�Ӥ�K�A PFA[3] �̪� opcode �O�ϵ۩񪺡C
\ �� target address �̪� binary code �h�O���`���C�G�o�Ӥ��{���n���U�o�I�C����� strcmp �]����� same?, �n��g�C

\ str:rts          ( str1 str2 length -- compare )
\                  compare string1[0] : string2[length-1], string1[1] : string2[length-2] ... 
\                  Return 0 if all same otherwise return none-zero.

                   : str:rts ( str rts len -- str rts compare ) \ ��g�� same?
                       1- -rot      \ len-1 str rts
                       2 pick 1+    \ len-1 str rts len
                       for aft      \ len-1 str rts 
                         over       \ len-1 str rts str
                         3 pick     \ len-1 str rts str len-1
                         r@         \ len-1 str rts str len-1 count     the count-- was done by DONXT.
                         -          \ len-1 str rts str len-1-count
                         +          \ len-1 str rts str+i
                         c@         \ len-1 str rts char(str+i)         where i=0,1,2,3,...
                         over       \ len-1 str rts char(str+i) rts
                         r@         \ len-1 str rts char(str+i) rts count        where count=len-1, len-2, len-3, ...
                         +          \ len-1 str rts char(str+i) rts+count
                         c@         \ len-1 str rts char(str+i) char(rts+count)
                         -          \ len-1 str rts char(str+i)-char(rts+count)
                         if         \ len-1 str rts                stop comparing if not same.
                           r>       \ len-1 str rts count [empty]
                           drop     \ len-1 str rts     
                           rot drop \ str rts
                           -1 exit  \ str rts -1                   not same
                         then       \ len-1 str rts 
                       then next    \ len-1 str rts                [ count-- ]
                       rot drop 0   \ str rts 0
                   ;

: disasm-match-opcode?  ( addr PFA[2] -- addr flag ) \ 0=same -1=unknown
    dup cell+               \ addr pfa(2) &code
    swap                    \ addr &code  pfa(2)
    @                       \ addr &code  length
    str:rts                 \ addr &code  0=same?
    swap drop               \ addr 0=same?
;

\ .hexcode copy �@���A�令 .hexparameter for parameter printing. 
\ �����D���� 1 2 4 8 �󥲩�}�ӦL�C [ ] 
: .hexcode       ( code length -- ) \ print given length of op-code or parameters.
    for aft               \ code
      $100 /mod swap .b   \ code'
      space
    then next             \ code'
    drop                  \ empty
;

: .disasm-opcode ( addr PFA[2] -- opcodeLength )  \ print OP-code
    \ Input value:                                                          
    \     addr   : target opcode address
    \     pfa(2) : A pair of opcode info. Where pfa(2) is opcode length, pfa(3) is reversed-opcode
    \ Return value:
    \     opcodeLength  Value of pfa(2). Return this value let caller to skip used bytes.
    @          \ addr Len
    swap @     \ Len opcode
    over       \ Len opcode Len
    .hexcode   \ Len
;

: (.disasm-parameter)  ( addr pfa[6] -- addr' pfa' EOP ) \ EOP=1:End of patameters
    \ Instructions �̪� Parameter ���h��T�ӡC ���g�X�L�@�� parameter �� function�C �ή� call �Ө�T���N�n�F�C
    \ Input value:
    \     addr   Start of the CPU instructon parameter section.
    \     pfa(6) parameter list, end by a NULL.
    \ Return value:
    \     addr'  skip to next parameter or instruction.
    \     PFA'   points to next parameter
    \     1      means end-of-parameters.
    \ �ثe���L�A�̦h����� parameter. �ҥH�n call �T���A�ĤT���^ 1 �~�൲���A�o�˦��I�¡C
    \ ���e�o�Ӧp�G�N�O NULL ��M�^ 1 �����C���e�o�Ӧp�G�B�z�����A�]���n���W�^ 0�A�ݤ@���U
    \ �@�Ӧp�G�O NULL �]�^ 1.
    >r                    \ addr [PFA(6)]    \ head of parameter list
    r@ @                  \ addr length               get parameter length
    2dup + -rot           \ addr+length addr length   \ advance to next parameter
    dup if                \ addr' addr length
      swap @ swap         \ addr' (addr) length
      .hexcode            \ addr'
      r> cell+            \ addr' PFA'
      dup @ 0=            \ addr' PFA' flag    ���ӸӦ^ 0 ��ܦ��\�A�h�ݤ@���A�p�G�٦��U�@�ӫh�|��^�s�A���U�@�Ӧp�G�N�O NULL �h�^ 1�A�o�ˤ���o���C
      if                  \ if next pfa is NULL then skip it and drop 1 to terminate
        cell+ 1           \ addr' PFA' 1   \ skip the NULL ending of parameter list
      else                \ if next pfa is not NULL then leave it and drop 0 to go on
        0                 \ addr' PFA' 0
      then
    else                  \ addr' addr length  \ Parameter list reaches NULL 
      drop swap drop      \ addr               \ addr is next instruction
      r> 1                \ addr dummy T       \ pfa in this case is dummy
    then                  \ addr' PFA' flag=1=EOP   end of parameters
;

: .disasm-parameters   ( addr PFA[6] -- addr' )    \ print parameters
    (.disasm-parameter) ( addr' PFA' EOP? ) if drop exit then
    (.disasm-parameter) ( addr' PFA' EOP? ) drop drop 
;

\ �H�U�o�ӬO�n�� disassembler list �� call �� word. �L�ݭn���D�ۤv�� PFA, �o�i�H�b compile ��
\ compile �o��C Target address �h�O�� disassembler list �� call �ɵ��w�C
\ hcchen5600 2011/11/30 09:49:40 [ ] �L�X target linear address �w�g���\�A���i�H�i�@�B�d
\ �O�_ word �ӦL�X word name, �����n�C

: .relative-addr0 drop ; ( addr -- )

create '.relative-addr ' .relative-addr0 ,     \ default is print nothing.

: .linear-address-name  ( la -- )              \ print word name or noname.
    dup           \ la la
    .q space      \ la
    >name .id     \ empty          
;

: .relative-addr8    ( addr -- )  \ addr is next instruction address. That's the sufficiant info.
    dup           \ addr addr
    1-            \ addr addr-1
    c@            \ addr (addr-1)        offset
    movsx.rbx,bl  \ addr (addr-1)        don't forget to do the bit extension!
    +             \ addr+(addr-1)        target-addr = (addr-1), target=(addr-1)+addr
    space [char] ( emit  .linear-address-name [char] ) emit    
;    
    
: .relative-addr16    ( addr -- )  \ addr is next instruction address. That's the sufficiant info.
    dup           \ addr addr
    2 -           \ addr addr-2
    w@            \ addr (addr-2)        offset
    movsx.rbx,bx  \ addr (addr-2)        don't forget to do the bit extension!
    +             \ addr+(addr-2)        target-addr = (addr-2), target=(addr-2)+addr
    space [char] ( emit  .linear-address-name [char] ) emit    
;    

: .relative-addr32    ( addr -- )  \ addr is next instruction address. That's the sufficiant info.
    dup           \ addr addr
    4 -           \ addr addr-4
    d@            \ addr (addr-4)        offset
    movsx.rbx,ebx \ addr (addr-4)        don't forget to do the bit extension!
    +             \ addr+(addr-4)        target-addr = (addr-4), target=(addr-4)+addr
    space [char] ( emit  .linear-address-name [char] ) emit    
;    

: .relative-addr   ( addr -- ) \ print relative address for jmp jnc jc ... etc relative addressing commands.
    '.relative-addr \ entry point was set by each disassembler
    @execute        \ target
    ['] .relative-addr0 '.relative-addr !   \ return to default value. So none-relative addressing instructions don't care.
;    

: .disasm-instruction  ( PFA[0] addr -- addr' ) \ print op-code and parameters
    dup                     \ PFA[0] addr addr
    2 pick 2 cells +        \ PFA[0] addr addr PFA[2]
    .disasm-opcode          \ PFA[0] addr opcodeLength    print OP-code
    +                       \ PFA[0] addr'                source addr' points to parameters or next instruction
    over 6 cells +          \ PFA[0] addr  PFA(6)         parameter list. 
    .disasm-parameters      \ PFA[0] addr'                print parameters. addr' points to next instruction, PFA(n) points to mnemonic.
    over 4 cells +          \ pfa[0] addr' pra[4]         mnemonic string
    @ count $1f and type    \ PFA[0] addr'                print mnemonic
    dup .relative-addr      \ PFA[0] addr'                .relative-addr can be nop, .relative8 .relative16 or .relative32
    swap drop               \ addr'                       next instruction
;

\ �n�۰ʺ�X relative addrss for jmp.rel8 �����C .disasm-instruction  �̭��� calling .disasm-parameters
\ �n���������A�Υο諸�A�Υѥ~���� cfa �i�ӡC [ ] hcchen5600 2011/11/28 22:33:01 
\ That's we need another .disasm-parameters-rel8 .disasm-parameters-rel16 and .disasm-parameters-rel32

: general-disassembler     ( addr rax=PFA -- addr' flag )  \ 0:ok -1:unknown instruction
    [ $48 c, $83 c, $C5 c, $F8 c, ]  \ add rbp,-8      \ $PUSH_RBX , assembler not ready �u�n�ζ몺�� binary �{����i�h�C
    [ $48 c, $89 c, $5D c, $00 c, ]  \ mov [rbp+0],rbx
    [ $48 c, $89 c, $c3 c,        ]  \ mov rbx,rax     \ rbx=rax \ addr PFA
    swap over                 \ pfa addr pfa
    2 cells +                 \ pfa addr PFA(2)        \ pfa(2)=opcodeLength pfa(3)=opcode
    disasm-match-opcode?      \ pfa addr flag          \ 0=same -1=unknown
    dup if                    \ pfa addr flag          \ if unknown
      rot drop                \ addr flag=-1           \ unknown instruction
    else                      \ pfa addr 0
      -rot                    \ flag pfa addr          \ flag=0
      .disasm-instruction     \ flag addr'
      swap                    \ addr' flag=0
    then                      \ addr' flag 
;

create disasmhead 0 ,          \ create disassembler list head

: setup-rel0   ['] .relative-addr0  '.relative-addr ! ;  
: setup-rel8   ['] .relative-addr8  '.relative-addr ! ;  
: setup-rel16  ['] .relative-addr16 '.relative-addr ! ;  
: setup-rel32  ['] .relative-addr32 '.relative-addr ! ;  
                   
: disassembler-generator ( rel -- )  \ specify relative addressing mode rel=0 8 16 or 32 bits relative address.
    last @ name> callsize+       \ rel PFA              \ get linkage address of this disassembler
    disasmhead @                 \ rel PFA disasmhead@  \ previous disassembler's PFA
    over                         \ rel PFA disasmhead@ PFA 
    !                            \ rel PFA              \ this PFA points to the earlier PFA
    dup disasmhead               \ rel PFA PFA disasmhead
    !                            \ rel PFA              \ disasmhead points to this PFA
    here                         \ rel PFA addr         \ disassembler entry point
    over cell+                   \ rel PFA addr pfa(1)  \ pfa(1) is disassembly entry vector
    !                            \ rel PFA
    over  0 = ( rel PFA rel=0?  ) if compile setup-rel0  then
    over  8 = ( rel PFA rel=8?  ) if compile setup-rel8  then
    over 16 = ( rel PFA rel=16? ) if compile setup-rel16 then
    swap 32 = (     PFA rel=32? ) if compile setup-rel32 then
    $" $48 c, $B8 c, , " $iEval  \ PFA   \ $48B8 16c64#: rax=n64
    compile general-disassembler
    [compile] exit              
;

\ This section is an example how to use 'disassembler-generator' in a assember class.
\ 
\ : 8c:     ( 8c -- )       \ op-code
\     create                            
\       ( pfa[0] )         0 ,  \ linkage
\       ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
\       ( pfa[2] )         1 ,  \ op-code size
\       ( pfa[3] )    ( 8c ) ,  \ 8c op-code, given from outside  
\       ( pfa[4] )    last @ ,  \ mnemonic name.
\       ( pfa[5] )         0 ,  \ dirty count
\       ( pfa[6] )         0 ,  \ parameter section  0 menas end of parameters
\       disassembler-generator
\     does>  ( -- )
\       r> 3 cells + @             \ PFA[3]
\       c,                         \ op-code
\ ;
\
\ $FC 8c: cld        immediate \ bits_16 CLD       bits_64 cld
\ $AD 8c: lodsw      immediate \ bits_16 LODSW     bits_64 lodsd eax,ds:[rsi]

    