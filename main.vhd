-- Il progetto e' stato svolto dal gruppo composto dagli studenti:
-- Gargano Jacopo Pio - Matricola 847989 - Codice Persona 10516854
-- Gioiosa Davide - Matricola 848123 - Codice Persona 10503787

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;





entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;




architecture project_reti_logiche of project_reti_logiche is


signal state: std_logic_vector(3 downto 0) :=  "0000";          -- segnale per salvare lo stato della macchina

constant S0: std_logic_vector(3 downto 0) := "0000";            -- stati della FSM
constant S1: std_logic_vector(3 downto 0) := "0001";
constant S2: std_logic_vector(3 downto 0) := "0010";
constant S3: std_logic_vector(3 downto 0) := "0011";
constant S4: std_logic_vector(3 downto 0) := "0100";
constant S5: std_logic_vector(3 downto 0) := "0101";
constant S6: std_logic_vector(3 downto 0) := "0110";
constant S7: std_logic_vector(3 downto 0) := "0111";
constant S8: std_logic_vector(3 downto 0) := "1000";
constant S9: std_logic_vector(3 downto 0) := "1001";
constant S10: std_logic_vector(3 downto 0) := "1010";
constant S11: std_logic_vector(3 downto 0) := "1011";
constant S12: std_logic_vector(3 downto 0) := "1100";

constant LSB_ram: std_logic_vector(15 downto 0) := "0000000000000000";              -- costanti per aumentare la leggibilita' del codice
constant MSB_ram: std_logic_vector(15 downto 0) := "0000000000000001";
constant colonne_ram: std_logic_vector(15 downto 0) := "0000000000000010";
constant righe_ram: std_logic_vector(15 downto 0) := "0000000000000011";
constant soglia_ram: std_logic_vector(15 downto 0) := "0000000000000100";
constant zero_eightbits: std_logic_vector(7 downto 0) := "00000000";
constant zero_sixteenbits: std_logic_vector(15 downto 0) := "0000000000000000";

signal colonne: std_logic_vector(7 downto 0) := zero_eightbits;                     -- segnali per gestire la FSM e salvare i valori dalla RAM
signal updated_colonne: std_logic_vector(7 downto 0) := zero_eightbits;
signal righe: std_logic_vector(7 downto 0) := zero_eightbits;
signal updated_righe: std_logic_vector(7 downto 0) := zero_eightbits;
signal soglia: std_logic_vector(7 downto 0) := zero_eightbits;

signal colonna_left: std_logic_vector(7 downto 0) := "11111111";                    -- segnali per salvare i vertici del rettangolo minimo
signal colonna_right: std_logic_vector(7 downto 0) := zero_eightbits;
signal riga_up: std_logic_vector(7 downto 0) := "11111111";
signal riga_down: std_logic_vector(7 downto 0) := zero_eightbits;

signal left: std_logic_vector(9 downto 0) := "0000000000";                -- segnali ausiliari per l'esecuzione dell'algoritmo di ricerca spirale
signal right: std_logic_vector(9 downto 0) := "0000000000";               -- primo bit indica flag done ( 0 false, 1 true ) -- secondo bit indica flag uninitialized o meno
signal up: std_logic_vector(9 downto 0) := "0000000000";
signal down: std_logic_vector(9 downto 0) := "0000000000";

signal current_colonna: std_logic_vector(7 downto 0) := zero_eightbits;
signal current_riga: std_logic_vector(7 downto 0) := zero_eightbits;
signal current_address: std_logic_vector(15 downto 0) := zero_sixteenbits;

signal base: std_logic_vector(7 downto 0) := zero_eightbits;                        -- segnali ausiliari per il calcolo del risultato
signal height: std_logic_vector(7 downto 0) := zero_eightbits;
signal area: std_logic_vector(15 downto 0) := zero_sixteenbits;

signal flag_empty: std_logic := '1';                                            -- 1 se immagine vuota, 0 se immagine non vuota
signal flag_striscia_colonne: std_logic_vector(1 downto 0) := "00";             -- 00 corrisponde a UNINITIALIZED
signal flag_striscia_righe: std_logic_vector(1 downto 0) := "00";               -- 00 corrisponde a UNINITIALIZED
signal flag_done: std_logic := '0';                                             -- flag ausiliaria nell'implementazione dell'algoritmo


begin
       
process(i_clk, i_start, i_rst)
begin

if falling_edge(i_clk)					-- l'algoritmo viene eseguito durante il fronte di discesa del clock
then
if(i_rst = '1' or (i_start = '1' and state /= S0))      -- se si riceve un reset oppure uno start allora bisogna resettare tutti i segnali
then
   
    colonne <= zero_eightbits;
    righe <= zero_eightbits;
    soglia <= zero_eightbits;
    updated_colonne <= zero_eightbits;
    updated_righe <= zero_eightbits;
    colonna_left <= "11111111";
    colonna_right <= zero_eightbits;
    riga_up <= "11111111";
    riga_down <= zero_eightbits;
    left <= "0000000000";
    right <= "0000000000";
    up <= "0000000000";
    down <= "0000000000";
    current_colonna <= "00000000";
    current_riga <= "00000000";
    base <= zero_eightbits;
    height <= zero_eightbits;
    area  <= zero_sixteenbits;
    current_address <= zero_sixteenbits;
    flag_empty <= '1';
    flag_striscia_colonne <= "00";
    flag_striscia_righe <= "00";
    flag_done <= '0';    
    
    o_we <= '0';
    o_done <= '0';
    
    if(i_rst = '1')
    then state <= S1;
         o_en <= '0';
    else state <= S2;
         o_en <= '1';   
    end if;
 
else
case state is

     -- S0: stato in cui si aspetta un segnale di reset
     when S0 =>
        state <= S0;

     -- S1: stato in cui si aspetta un segnale di start
     when S1 =>
        if(i_start = '1')
        then state <= S2;
             o_en <= '1';
             o_we <= '0';
             o_done <= '0';
        else
            state <= S1;
        end if;
     
     -- S2: stato in cui si inizia la lettura del numero di colonne
     when S2 =>
        o_address <= colonne_ram;
        state <= S3;
        
     -- S3: stato in cui si inizia la lettura del numero di righe e si assegna i_data alle colonne
     when S3 =>
        o_address <= righe_ram;
        if(i_data = zero_eightbits)				-- se le colonne sono 0 allora l'area ? pari a 0
        then state <= S9;
        else
            colonne <= i_data;
            updated_colonne <= i_data;
            state <= S4;
        end if;
        
     -- S4: stato in cui si inizia la lettura della soglia e si assegna i_data alle righe
     when S4 =>
        o_address <= soglia_ram;	
        if(i_data = zero_eightbits)				-- se le righe sono 0 allora l'area ? pari a 0
        then state <= S9;
        else
            righe <= i_data;
            updated_righe <= i_data;
            state <= S5;
        end if;       
        
     -- S5: stato in cui si assegna i_data alla soglia e ha inizio l'algoritmo di ricerca dei vertici del rettangolo minimo   
     when S5 =>
     if(i_data = zero_eightbits)				-- se la soglia ? 0 allora l'area ? pari a tutta l'immagine in ingresso
     then state <= S7;
          colonna_right <= colonne -1;
          colonna_left <= zero_eightbits;
          riga_up <= zero_eightbits;
          riga_down <= righe -1;
          flag_empty <= '0';
           
     else
        soglia <= i_data;
        right(7 downto 0) <= colonne;
        down(7 downto 0) <= righe;
        o_address <= "0000000000000101";			-- primo indirizzo da leggere
        current_address <= "0000000000000101";
        if(i_rst ='1')
        then state <= S0;
        else state <= S6;
        end if;
     end if;
     


     -- S6: stato in cui è implementato l'algoritmo di ricerca spirale
     
	when S6 =>
     
     -- AGGIORNAMENTO delle variabili costituenti i vertici del rettangolo minimo
        if(up(9) = '1' and down(9) = '1' and left(9) = '1' and right(9) = '1')			-- se tutti i segnali ausiliari sono stati settati
        then state <= S7;
	     flag_done <= '1';	
        else
        if(i_data >= soglia)
        then
            flag_empty <= '0';
            if(current_colonna <= colonna_left and left(9) = '0')
            then colonna_left <= current_colonna;
                 if(current_colonna = 0 or (current_colonna -1 = left(7 downto 0) and left(8) = '1'))
                 then left(9) <= '1';
                 end if;

            end if;
            if(current_colonna >= colonna_right and right(9) = '0')
            then colonna_right <= current_colonna;
                 if(current_colonna = colonne-1 or (current_colonna +1 = right(7 downto 0) and right(8) = '1'))
                 then right(9) <= '1';
                 end if;

            end if;
            if(current_riga >= riga_down and down(9) = '0')
            then riga_down <= current_riga;
                 if(current_riga = righe -1 or (current_riga +1 = down(7 downto 0) and down(8) = '1'))
                 then down(9) <= '1';
                 end if;

            end if;
            if(current_riga <= riga_up and up(9) = '0')
            then riga_up <= current_riga;
                if(current_riga = 0 or (current_riga -1 = up(7 downto 0) and up(8) = '1'))
                then up(9) <= '1';
                end if;

            end if;
        else
            if(current_colonna +1 = updated_colonne and current_riga = righe-updated_righe and up(9) = '0')            -- ALTO DX
            then up(7 downto 0) <= current_riga;
                 up(8) <= '1';  									-- non e piu Uninitialized
            end if;
            if(current_colonna +1 = updated_colonne and current_riga +1 = updated_righe and right(9) = '0')         -- BASSO DX
            then right(7 downto 0) <= current_colonna;
                 right(8) <= '1';
            end if;
            if(current_colonna = colonne - updated_colonne and current_riga = updated_righe and down(9) = '0')     -- BASSO SX
            then down(7 downto 0) <= current_riga;
                 down(8) <= '1';
            end if;
            if(current_colonna = colonne - updated_colonne and current_riga = righe - updated_righe and left(9) = '0' and current_colonna /= current_riga)        -- ALTO SX and current_colonna /= current_riga
            then left(7 downto 0) <= current_colonna;
                 left(8) <= '1';
            end if;
            
        end if;


      -- FINE AGGIORNAMENTO





      -- RICERCA SPIRALE
             
        if(flag_done = '0')    
        then if(current_colonna +1 = updated_colonne)
                 then 
                      if(current_riga +1 = updated_righe)           -- ANGOLO BASSO DX oppure QUADRATO 1X1
                      then
                        if(colonne = righe and current_colonna = current_riga and colonne - updated_colonne = current_colonna)
                        then state <= S7;
                        elsif(colonne = righe and current_colonna = current_riga and flag_striscia_colonne = "10") 
                        then state <= S7;
                        elsif(colonne = righe and current_colonna = current_riga and flag_striscia_colonne = "01")
                        then current_colonna <= current_colonna -1;
                             o_address <= current_address -1;
                             current_address <= current_address -1;
                             updated_righe <= updated_righe -1;
                        elsif(righe = "00000001" or colonne = "00000001")
                        then state <= S7;
                        elsif(colonne > righe and flag_striscia_colonne = "10")
                        then state <= S7;
                        elsif(colonne < righe and flag_striscia_righe = "10")
                        then state <= S7;
                        else
                            current_colonna <= current_colonna -1;
                            o_address <= current_address -1;
                            current_address <= current_address -1;
                            updated_righe <= updated_righe -1;
                        end if;
          
                      else
                         if(current_riga = righe-updated_righe)             -- ANGOLO ALTO DX
                         then
                            if(colonne >= righe)
                            then
                                if(current_riga = updated_righe -2)                         -- RETTANGOLO COLONNE
                                then flag_striscia_colonne <= "01";
                                end if;
                            else
                                if(current_colonna = current_riga)                    -- STRISCIA RIGHE
                                then flag_striscia_righe <= "10";     
                                end if;                  
                            end if;
                            
                            current_riga <= current_riga +1;                        -- NORMALE (MOVIMENTO GIU)    
                            o_address <= current_address + colonne; -- scendi in verticale di 1
                            current_address <= current_address + colonne;
                            
                         else                                               -- MOVIMENTO GIU
                            current_riga <= current_riga +1;
                            o_address <= current_address + colonne; -- scendi in verticale di 1
                            current_address <= current_address + colonne;
                         end if;
                      end if;
             elsif(current_colonna = colonne - updated_colonne)     
             then
                if(current_riga = righe - updated_righe)                
                then
                    if(current_colonna = current_riga)                              -- INIZIO
                    then o_address <= current_address +1; 
                         current_address <= current_address +1;
                         current_colonna <= current_colonna +1;
                         if(righe > colonne and current_colonna = updated_colonne -2)                    -- RETTANGOLO RIGHE
                         then flag_striscia_righe <= "01";
                         elsif(colonne > righe and current_riga = updated_righe -1)             -- STRISCIA COLONNE
                         then flag_striscia_colonne <= "10";
                         end if;
                    else                                                            -- ANGOLO ALTO SX
                        if(flag_striscia_righe = "01" or flag_striscia_colonne = "01")
                        then state <= S7;
                        end if;
                        o_address <= current_address +1; 
                        current_address <= current_address +1;
                        current_colonna <= current_colonna +1;
                        updated_colonne <= updated_colonne -1;
                   end if;
                else                                                          -- ANGOLO BASSO SX
                    if(colonne >= righe and flag_striscia_colonne = "01")
                    then state <= S7;
                    
                    end if;
                    current_riga <= current_riga -1;                       --MOVIMENTO SU
                    o_address <= current_address - colonne; -- sali in verticale di 1
                    current_address <= current_address - colonne; 
                end if;
             elsif(current_riga = righe - updated_righe)        -- MOVIMENTO DX
                then
                    if(flag_striscia_colonne = "01")
                    then o_address <= current_address -1; 
                         current_address <= current_address -1;
                         current_colonna <= current_colonna -1;
                    else 
                        o_address <= current_address +1; 
                        current_address <= current_address +1;
                        current_colonna <= current_colonna +1;
                    end if;
             else o_address <= current_address -1;              -- MOVIMENTO SX
                  current_address <= current_address -1;
                  current_colonna <= current_colonna -1;
             end if;
           end if;
         end if;
     



     -- S7: stato in cui si calcolano base e altezza del rettangolo minimo
     when S7 =>
     if(flag_empty = '1')
             then base <= zero_eightbits;
                  height <= zero_eightbits;
             elsif(colonna_right = "11111111" and colonna_left = zero_eightbits and riga_down = zero_eightbits and riga_up = zero_eightbits)
             then base <= colonna_right;
                  height <= riga_down;
             elsif(colonna_right = "11111111" and colonna_left = zero_eightbits)
             then base <= colonna_right;
                  height <= riga_down - riga_up +1;
             elsif(riga_down = "11111111" and riga_up = zero_eightbits)
             then base <= colonna_right - colonna_left +1;
                  height <= riga_down;
             else
                  base <= colonna_right - colonna_left +1;
                  height <= riga_down - riga_up +1;
             end if;
             state <= S8;
        
 
        state <= S8;
     
     -- S8: stato in cui si calcola l'area del rettangolo minimo
     when S8 =>
        area <= base * height;
        o_we <= '1';
        state <= S9;
        
     -- S9: stato in cui si scrivono i LSB dell'area del rettangolo minimo
     when S9 =>
        o_address <= LSB_ram;
        o_data <= area(7 downto 0);
        state <= S10;
     
     -- S10: stato in cui si scrivono i MSB dell'area del rettangolo minimo
     when S10 =>
        o_address <= MSB_ram;
        o_data <= area(15 downto 8);
        state <= S11;   

     -- S11: stato in cui si porta per un ciclo di clock l'uscita o_done a livello logico alto
     when S11 =>
        o_done <= '1';
        o_we <= '0';
        o_en <= '0';
        state <= S12;
     
     -- S12: stato in cui si riporta l'uscita o_done a livello logico basso e si resettano tutti i segnali per avviare una nuova procedura
     when S12 => 
        o_done <= '0';
        
        colonne <= zero_eightbits;
        righe <= zero_eightbits;
        soglia <= zero_eightbits;
        updated_colonne <= zero_eightbits;
        updated_righe <= zero_eightbits;
        colonna_left <= "11111111";
        colonna_right <= zero_eightbits;
        riga_up <= "11111111";
        riga_down <= zero_eightbits;
        left <= "0000000000";
        right <= "0000000000";
        up <= "0000000000";
        down <= "0000000000";
        current_colonna <= zero_eightbits;
        current_riga <= zero_eightbits;
        base <= zero_eightbits;
        height <= zero_eightbits;
        area  <= zero_sixteenbits;
        current_address <= zero_sixteenbits;
        flag_empty <= '1';
        flag_striscia_colonne <= "00";
        flag_striscia_righe <= "00";
        flag_done <= '0';
        state <= S1;         
     
	when others => state <= state;

  end case;

end if;
end if;
end process;


    
end project_reti_logiche;
