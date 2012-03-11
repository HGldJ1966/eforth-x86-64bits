
.(  including 025_disasm_p2.f ) cr

disassembler definitions


// Disassembler Part II

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

: disasm1instruction ( addr -- addr flag )  \ 0:ok -1:unknown instruction
   disasmhead @    \ addr pfa
   swap            \ pfa addr
   begin           \ pfa addr
     over          \ pfa addr  pfa
     cell+         \ pfa addr  entry-pointer
     @execute      \ pfa addr' flag             \ 0:ok -1:unknown instruction
     \ �p�G ok addr' �w�g���V�U�@�� instruction. �� function �ӵ����F�C�Ǧ^ 0 ��ܦ��\�C
     \ �p�G failed, addr  ���ܡA���U�ӭn�ǳƤU�@�� disassembler �� entry point.�~����աC�C�C�`�N�I�쩳�ɪ��B�z�C
     \ �ҥH�u�� failed �n�ǳ� repeat 
     dup -1 = 
   while           \ pfa addr -1
     drop swap     \ addr pfa
     @ dup         \ addr pfa' pfa'
     if            \ addr pfa'
       swap        \ pfa' addr   \ try next disassembler
     else          \ addr NULL
       0=          \ addr -1     \ totally Not found
       exit
     then          \ pfa' addr
   repeat          \ pfa' addr
   rot drop        \ addr flag   \ ok
;   

: disassembler ( addr -- addr' ) \ To be used in console mode.
    base @ >r hex   \ [base] save base
    cr
    begin                 \ addr'
      dup                 \ addr' addr'
      u.                  \ addr'
      [char] : emit space \ addr'
      disasm1instruction  \ addr' flag=[0,-1]
      if                  \ addr                  unknown instruction print binary code
        dup               \ addr  addr 
        c@ .b             \ addr  
        1+                \ addr'                 this byte unknown, skip to next address
      then                \ addr' 
      nuf? space cr       \ addr' break?
    until                 \ addr'
    r> base !       \ restore base
;      
    
' disassembler alias u

// pfa(5) is dirty count. We need a command to list all of them. Start from disasmhead.

\
\ list-cpu-instructions  ( -- )
\                  Every disassembler object has a linkage. The linked list head is disasmhead@.
\                  This command go through the entire list. Print all instructions and their
\                  dirty count. �ӫ��O�C compile ��@�� dirty count �N�|�[�@�C

                   : list-cpu-instructions
                     disasmhead @           \ pfa1(0)               points to first pfa
                     begin                  \ pfan
                       dup 5 cells +        \ pfa1 pfa1(5)          
                       @                    \ pfa1 pfa1.dirtyCount  
                       10 .r space          \ pfa1                  print dirty count
                       dup 4 cells +        \ pfa1 pfa1.mnemonic    
                       @ count $1f and type \ pfa1                  print mnemonic
                       cr @                 \ pfa2
                       dup 0=               \ pfa2 pfa2=0?
                     until                  \ pfa2
                     drop
                   ;  
                   
                         
                         