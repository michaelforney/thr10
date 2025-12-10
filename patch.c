#include "thr10.h"

static bool cab_bypass;

int
wrap_dsp_command(struct dsp_command *cmd)
{
	if (cab_bypass && cmd->block == 2) {
		switch (cmd->type) {
		case 1:
			if (cmd->field2 != 0)
				break;
			/* fallthrough */
		case 0:
			cmd->type = 1;
			cmd->field2 = 0;
			cmd->field3 = 0;
			break;
		}
	}
	return dsp_command(cmd);
}

void
wrap_control_handle_buttons(void)
{
	static unsigned short button_save;
	static unsigned short wait_release;
	unsigned short button, button_prev;

	panel_get_buttons(&button);
	button_prev = button_save;
	button_save = button;
	if (wait_release) {
		if (button)
			return;
		wait_release = false;
	}
	if (!tuner_active && button & button_prev & PANEL_BUTTON_TAPTEMPO) {
		if (button & ~button_prev & PANEL_BUTTON_PRESET1) {
			cab_bypass ^= 1;
			panel_set_led(PANEL_LED_TUNE_LEFT, !cab_bypass);
			panel_set_led(PANEL_LED_TUNE_RIGHT, !cab_bypass);
			amp_set_cabinet(cab_bypass ? 6 : amp_state.cabinet, 1);
			wait_release = true;
			return;
		}
	}
	control_handle_buttons();
}
