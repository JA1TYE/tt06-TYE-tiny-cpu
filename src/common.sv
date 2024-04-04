typedef enum logic [1:0] {
    TYPE_IDLE = 2'b00,
    TYPE_IMEM_READ = 2'b01,
    TYPE_DMEM_READ = 2'b10,
    TYPE_DMEM_WRITE = 2'b11
} mem_type_t;

typedef enum logic [3:0] {
    STATE_FETCH = 4'h0,
    STATE_FETCH_WAIT = 4'h1,
    STATE_DECODE = 4'h2,
    STATE_ALU_EXEC = 4'h3,
    STATE_LOAD_MEM = 4'h4,
    STATE_LOAD_MEM_WAIT = 4'h5,
    STATE_STORE_MEM = 4'h6,
    STATE_STORE_MEM_WAIT = 4'h7,
    STATE_UPDATE_PC = 4'h8
} sys_state_t;