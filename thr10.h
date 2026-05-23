/* uart */
int uart_write(unsigned len, void *buf, unsigned *retlen);
void uart_flush(void);

/* panel i/o */
enum panel_button {
	PANEL_BUTTON_TAPTEMPO = 0x01,
	PANEL_BUTTON_PRESET1  = 0x02,
	PANEL_BUTTON_PRESET2  = 0x04,
	PANEL_BUTTON_PRESET3  = 0x08,
	PANEL_BUTTON_PRESET4  = 0x10,
	PANEL_BUTTON_PRESET5  = 0x20,
};

enum panel_led {
	PANEL_LED_AMP_0       = 0,
	PANEL_LED_AMP_1       = 1,
	PANEL_LED_AMP_2       = 2,
	PANEL_LED_AMP_3       = 3,
	PANEL_LED_AMP_4       = 4,
	PANEL_LED_AMP_5       = 5,
	PANEL_LED_AMP_6       = 6,
	PANEL_LED_AMP_7       = 7,
	PANEL_LED_TUNE_LEFT   = 8,
	PANEL_LED_TUNE_CENTER = 9,
	PANEL_LED_TUNE_RIGHT  = 10,
};

void panel_set_led(int led, int off);
int panel_get_buttons(unsigned short *buttons);

/* control */
void control_handle_buttons(void);
void control_set_speaker(int on);

extern bool control_headphone_connected;

/* amp emulation */
struct amp_state {
	unsigned char type;
	unsigned char gain;
	unsigned char master;
	unsigned char bass;
	unsigned char middle;
	unsigned char treble;
	unsigned char cabinet;
};

extern struct amp_state amp_state;

int amp_set_cabinet(int type, int source);

/* dsp */
struct dsp_command {
	unsigned short block;
	unsigned char type;
	unsigned char field2;
	unsigned short field3;
	unsigned short field4;
	unsigned short field5;
	unsigned field6;
	unsigned field7;
};
_Static_assert(sizeof(struct dsp_command) == 20, "incorrect struct dsp_command size");

int dsp_command(struct dsp_command *cmd);

/* tuner */
extern unsigned short tuner_active;
