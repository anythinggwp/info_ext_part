.386
dat segment use16
adr_pack db 16, 0, 1, 0
   dw buff, dat
   dq 0
buff db 512 dup(0)
msg_disk db 'physical disk 0:', , 0Ah, 0Dh, '$'
msg db 'logdisk - ', 11 dup(0), 'filesystem - ', 8 dup(0), 'capacity: lba = ', 10 dup(0), 'mbyte = ', 7 dup(0), , 0Ah, 0Dh, '$'
not_found db 'Extended partition or disk doesnt exist', 0Ah, 0Dh, '$'
first_EPR dd 0
prev_EPR dd 0
disk_ntfs db 'NTFS'
dat ends
lab segment use16
Assume ds:dat, cs:lab
  init_mem_seg:  mov bx, dat
      mov ds, bx
      mov bx, ds
      mov es, bx
;###############################################
  init_disk_0: call show_disk
      mov ah, 42h
      lea si, adr_pack
      mov dl, 80h
      int 13h
      jnc short search_init
      lea dx, not_found
      call def_msg
  init_disk_1: call show_disk
      mov ah, 42h
      lea si, adr_pack
      mov dl, 81h
      int 13h
      jnc short search_init
      lea dx, not_found
      call def_msg
  init_disk_2: call show_disk
      mov ah, 42h
      lea si, adr_pack
      mov dl, 82h
      int 13h
      jnc short search_init
      lea dx, not_found
      call def_msg
  init_disk_3: call show_disk
      mov ah, 42h
      lea si, adr_pack
      mov dl, 83h
      int 13h
      jnc short search_init
      lea dx, not_found
      call def_msg
   fin:  mov ah, 4Ch
           int 21h
;#####################################################
        search_init: lea si, buff
               mov cx, 4
;#####################################################
         srch_MBR:  cmp byte ptr ds:[si+450], 5h
            je short init_first_EPR
          cmp byte ptr ds:[si+450], 0Fh
          je short init_first_EPR
            add si, 10h
          loop srch_MBR
          lea dx, not_found
          call def_msg
;#####################################################
        srch_disk: cmp msg_disk+14, 31h
          je short init_disk_1
          cmp msg_disk+14, 32h
          je short init_disk_2
          cmp msg_disk+14, 33h
          je short init_disk_3
          jmp short fin
;#####################################################
     init_first_EPR: add si, 454
            lodsd
            mov dword ptr first_EPR, eax
            lea di, adr_pack+8
            stosd
            call switch
;#####################################################
     init_serch_EPR:   lea si, buff
;#####################################################
       search_EPR: cmp byte ptr ds:[si+450], 0
             je fin_EPR
           cmp byte ptr ds:[si+450], 5h
          je last_crypt
          cmp byte ptr ds:[si+450], 0Fh
          je last_crypt
          mov eax, dword ptr ds:[si+458]
          lea di, msg+67
          call translate ; Добавляем в сообщение LBA координаты 
          mov eax, dword ptr ds:[si+458]
          mov ebx, 512
          mul ebx
          mov ebx, 1024
          div ebx
          div ebx
          lea di, msg+82
          call translate
          cmp byte ptr ds:[si+450], 07h
          jne short log_system_fat32
;####################################################
 log_system_ntfs: lea di, msg+16
      lea si, disk_ntfs
      movsd
      lea di, msg+37
      movsd
      lea si, buff
      lea dx, msg
         call def_msg
      jmp short next_crypt
;####################################################
   log_system_fat32: cmp byte ptr ds:[si+450], 0Bh
         jne short log_system_fat16
         lea si, adr_pack+8
         lea di, prev_EPR
         movsd
         lea si, buff
         call init_srch_FAT
         call switch ; Попадаем в bootsector
         lea si, buff
         add si, 71
         call add_logname ; Добавляем имя и название файловой системы
         lea si, prev_EPR
         lea di, adr_pack+8
         movsd
         call switch
         lea dx, msg
         call def_msg
         jmp short next_crypt
;####################################################
   log_system_fat16: cmp byte ptr ds:[si+450], 06h
         jne short last_crypt
         lea si, adr_pack+8
         lea di, prev_EPR
         movsd
         lea si, buff
         call init_srch_FAT
         call switch ; Попадаем в bootsector
         lea si, buff
         add si, 43
         call add_logname ; Добавляем имя
         lea si, prev_EPR
         lea di, adr_pack+8
         movsd
         call switch
         lea dx, msg
         call def_msg
;####################################################
   next_crypt: lea si, buff+16
       jmp search_EPR
   last_crypt: add si, 454
      lodsd
      add eax, dword ptr first_EPR
      lea di, adr_pack+8
      stosd
         call switch
         jmp init_serch_EPR
      fin_EPR: jmp srch_disk



 translate proc 
   start:  mov ebx, 10
          mov edx, 0
          div ebx
          add dl, 30h
          mov byte ptr ds:[di], dl
          dec di
          cmp ax, 0Ah
          ja short start
          je short start
          add al, 30h
          mov byte ptr ds:[di], al
      RET
 translate endp
 switch proc
   mov ah, 42h    
   lea si, adr_pack  
   mov dl, byte ptr msg_disk+14 ; Перемещаем в регистр сиволический номер ЖД 
   add dl, 4Fh ; Переформатируем его для прервания
   int 13h
   RET 
 switch endp
 show_disk proc
      mov ah, 9h
      lea dx, msg_disk
      int 21h
      add msg_disk+14, 1h
      RET
 show_disk endp
 def_msg proc
  mov ah, 9h
  int 21h
  RET
 def_msg endp
 init_srch_FAT proc
  add si, 454
   lodsd
   add dword ptr adr_pack+8, eax
   RET
 init_srch_FAT endp
 add_logname proc
    mov cx, 11 
    lea di, msg+10
 beg_logn: movsb
       loop beg_logn
       mov cx, 8
       lea di, msg+33
   beg_logFS: movsb
       loop beg_logFS
    RET
 add_logname endp
            

lab ends
 End init_mem_seg
