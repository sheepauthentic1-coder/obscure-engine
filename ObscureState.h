#pragma once
// Struct trạng thái dùng chung giữa obscure_engine.cpp và menu UIKit.
// Layout và offset giữ nguyên như file gốc đã ghi chú.
#include <cstdint>

struct RenderContextState {
    bool state_alpha;                // 0x00
    bool state_beta;                 // 0x01
    bool state_gamma;                // 0x02
    bool state_delta;                // 0x03
    bool state_epsilon;              // 0x04
    bool state_zeta;                 // 0x05
    uint8_t pad_1[0x08 - 0x06];
    float metric_scale;              // 0x08

    uint8_t pad_2[0x0E - 0x0C];
    bool data_node_a;                // 0x0E
    bool data_node_b;                // 0x0F
    bool data_node_c;                // 0x10
    bool data_node_d;                // 0x11
    bool data_node_e;                // 0x12

    uint8_t pad_3[0x16 - 0x13];
    bool flag_routine_1;             // 0x16
    bool flag_routine_2;             // 0x17
    bool flag_routine_3;             // 0x18
    bool flag_routine_4;             // 0x19

    uint8_t pad_4[0x1D - 0x1A];
    bool ctrl_mode_a;                // 0x1D
    uint8_t pad_5[0x20 - 0x1E];
    float val_speed_a;               // 0x20

    bool ctrl_mode_b;                // 0x24
    uint8_t pad_7[0x28 - 0x25];
    float val_speed_b;               // 0x28

    bool view_zoom_en;               // 0x2C
    uint8_t pad_9[0x30 - 0x2D];
    float view_zoom_factor;          // 0x30

    bool perf_sync_120;              // 0x34
    bool perf_debug_info;            // 0x35
    bool sys_bypass_sec;             // 0x36
    bool sys_mock_id;                // 0x37
};

// Một instance duy nhất, dùng chung cho cả logic gốc và menu.
RenderContextState &ObscureState();

// Hiện menu UIKit. Định nghĩa trong ObscureMenu.mm.
extern "C" void ObscureShowMenu();
