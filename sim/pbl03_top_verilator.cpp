#include "Vtop_pbl03.h"
#include "verilated.h"

#include <array>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

struct Scenario {
    VerilatedContext context;
    Vtop_pbl03 dut{&context};
    std::uint64_t clock_cycles = 0;
    std::uint64_t checks = 0;
    bool monitor_busy = false;
    bool busy_seen = false;

    void tick(int keys, int switches) {
        dut.KEY = static_cast<CData>(keys);
        dut.SW = static_cast<SData>(switches);
        dut.MAX10_CLK1_50 = 0;
        dut.eval();
        context.timeInc(10);
        dut.MAX10_CLK1_50 = 1;
        dut.eval();
        context.timeInc(10);
        ++clock_cycles;
        if (monitor_busy && (led() & 1U) != 0)
            busy_seen = true;
    }

    void cycles(int keys, int switches, int count) {
        for (int i = 0; i < count; ++i)
            tick(keys, switches);
    }

    void require(bool condition, const std::string &message) {
        if (!condition)
            throw std::runtime_error(message);
    }

    void expectEqual(unsigned actual, unsigned expected, const std::string &label) {
        if (actual != expected) {
            throw std::runtime_error(label + " expected 0x" + hex(expected) +
                                     ", observed 0x" + hex(actual));
        }
        ++checks;
    }

    static std::string hex(unsigned value) {
        constexpr char digits[] = "0123456789abcdef";
        std::string result;
        do {
            result.insert(result.begin(), digits[value & 0xf]);
            value >>= 4;
        } while (value != 0);
        return result;
    }

    unsigned led() const { return dut.LEDR; }

    void expectStatus(int expected_led, int error_index) {
        std::array<unsigned, 6> expected_hex = {0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f};
        expectEqual(led(), static_cast<unsigned>(expected_led), "LEDR");
        if (error_index >= 0) {
            expected_hex[5] = 0x06;
            expected_hex[4] = 0x2f;
            expected_hex[3] = 0x2f;
            expected_hex[1] = (error_index == 0 || error_index == 2) ? 0x0e : 0x63;
            expected_hex[0] = error_index < 2 ? 0x79 : 0x24;
        }
        const std::array<unsigned, 6> actual_hex = {
            dut.HEX0, dut.HEX1, dut.HEX2, dut.HEX3, dut.HEX4, dut.HEX5};
        for (unsigned i = 0; i < actual_hex.size(); ++i)
            expectEqual(actual_hex[i], expected_hex[i], "HEX" + std::to_string(i));
    }

    void resetSession() {
        cycles(1, 0, 8); // KEY1 pressed (active low)
        cycles(3, 0, 8); // release both keys
        expectStatus(0, -1);
        std::cout << "TOP VERILATOR PASS: KEY1 reset clears status and releases cleanly\n";
    }

    static int signedMagnitude(int coefficient) {
        const int magnitude = coefficient < 0 ? -coefficient : coefficient;
        return magnitude | (coefficient < 0 ? 0x100 : 0);
    }

    void clickKey0(int value, const std::string &label) {
        cycles(2, signedMagnitude(value), 7); // KEY0 pressed
        cycles(3, signedMagnitude(value), 7); // KEY0 released
        expectStatus(0, -1);
        if (!label.empty())
            std::cout << "TOP VERILATOR PASS: " << label << '\n';
    }

    void clickKey0Raw(int switches, const std::string &label) {
        cycles(2, switches, 7);
        cycles(3, switches, 7);
        expectStatus(0, -1);
        std::cout << "TOP VERILATOR PASS: " << label << '\n';
    }

    void captureTuple(const std::array<int, 6> &coefficients) {
        static const std::array<const char *, 6> names = {
            "capture a1", "capture b1", "capture c1", "capture a2", "capture b2",
            "capture c2; review only"};
        for (unsigned i = 0; i < coefficients.size(); ++i)
            clickKey0(coefficients[i], names[i]);
    }

    void startProcessing(int expected_led, int expected_error, const std::string &label) {
        constexpr std::uint64_t frame_system_clocks = 800ULL * 525ULL * 2ULL;
        busy_seen = false;
        monitor_busy = true;
        cycles(2, 0, 7);
        cycles(3, 0, 7);
        for (std::uint64_t i = 0; i < frame_system_clocks && (led() & 2U) == 0; ++i) {
            tick(3, 0);
        }
        monitor_busy = false;
        require((led() & 2U) != 0, label + ": DONE timeout after one full 800x525 VGA frame");
        require((led() & 1U) == 0, label + ": DONE asserted while BUSY remains active");
        expectStatus(expected_led, expected_error);
        require(busy_seen, label + ": BUSY was never observed");
        cycles(3, 0, 5);
        expectStatus(expected_led, expected_error);
        std::cout << "TOP VERILATOR PASS: " << label << '\n';
    }

    static std::int64_t functionY(int a, int b, int c, int x) {
        return static_cast<std::int64_t>(a) * x * x +
               static_cast<std::int64_t>(b) * x + c;
    }

    static std::int64_t derivativeY(int a, int b, int x) {
        return static_cast<std::int64_t>(2) * a * x + b;
    }

    static int roundRational(std::int64_t numerator, std::int64_t denominator) {
        const bool negative = numerator < 0;
        const std::uint64_t magnitude = static_cast<std::uint64_t>(negative ? -numerator : numerator);
        const std::uint64_t den = static_cast<std::uint64_t>(denominator);
        std::uint64_t quotient = magnitude / den;
        const std::uint64_t remainder = magnitude % den;
        if (2 * remainder >= den)
            ++quotient;
        return negative ? -static_cast<int>(quotient) : static_cast<int>(quotient);
    }

    static bool vertexPixel(int a, int b, int c, int &x, int &y) {
        if (a == 0)
            return false;
        const std::int64_t sign = a < 0 ? -1 : 1;
        const std::int64_t y_num = sign * (4LL * a * c - static_cast<std::int64_t>(b) * b);
        const std::int64_t y_den = 4LL * std::abs(a);
        if (y_num < -239LL * y_den || y_num > 240LL * y_den)
            return false;
        const std::int64_t x_num = a > 0 ? -static_cast<std::int64_t>(b) : b;
        const std::int64_t x_den = 2LL * std::abs(a);
        x = roundRational(x_num, x_den);
        y = roundRational(y_num, y_den);
        return true;
    }

    static std::array<int, 2> roots(int a, int b, int c, bool &valid) {
        const std::int64_t delta = static_cast<std::int64_t>(b) * b -
                                   4LL * a * c;
        valid = a != 0 && delta >= 0;
        if (!valid)
            return {0, 0};
        const double radical = std::sqrt(static_cast<double>(delta));
        const double denominator = static_cast<double>(2 * a);
        return {static_cast<int>(std::round((-b + radical) / denominator)),
                static_cast<int>(std::round((-b - radical) / denominator))};
    }

    static int glyphIndex(char ch) {
        if (ch >= '0' && ch <= '9') return ch - '0';
        if (ch == 'F') return 10;
        if (ch == 'x') return 11;
        if (ch == '=') return 12;
        if (ch == '+') return 13;
        if (ch == '-') return 14;
        return -1;
    }

    static bool labelPixel(int x, int y, int root, int y_base, const std::string &prefix) {
        static const std::array<std::array<const char *, 7>, 15> font = {{
            {{"01110","10001","10011","10101","11001","10001","01110"}},
            {{"00100","01100","00100","00100","00100","00100","01110"}},
            {{"01110","10001","00001","00010","00100","01000","11111"}},
            {{"11110","00001","00001","01110","00001","00001","11110"}},
            {{"00010","00110","01010","10010","11111","00010","00010"}},
            {{"11111","10000","10000","11110","00001","00001","11110"}},
            {{"01110","10000","10000","11110","10001","10001","01110"}},
            {{"11111","00001","00010","00100","01000","01000","01000"}},
            {{"01110","10001","10001","01110","10001","10001","01110"}},
            {{"01110","10001","10001","01111","00001","00001","01110"}},
            {{"11111","10000","10000","11110","10000","10000","10000"}},
            {{"00000","10001","01010","00100","01010","10001","00000"}},
            {{"00000","00000","11111","00000","11111","00000","00000"}},
            {{"00000","00100","00100","11111","00100","00100","00000"}},
            {{"00000","00000","00000","11111","00000","00000","00000"}}
        }};
        if (y < y_base || y >= y_base + 7)
            return false;
        const int local_x = x - (320 + root - 27);
        if (local_x < 0 || local_x >= 54 || local_x % 6 >= 5)
            return false;
        char digits[4];
        const int magnitude = std::abs(root);
        digits[0] = static_cast<char>('0' + (magnitude / 100) % 10);
        digits[1] = static_cast<char>('0' + (magnitude / 10) % 10);
        digits[2] = static_cast<char>('0' + magnitude % 10);
        digits[3] = '\0';
        const std::string text = prefix + (root < 0 ? "-" : "+") + digits;
        const int glyph = glyphIndex(text[static_cast<std::size_t>(local_x / 6)]);
        return glyph >= 0 && font[static_cast<std::size_t>(glyph)][static_cast<std::size_t>(y - y_base)][local_x % 6] == '1';
    }

    static std::array<unsigned, 3> referenceRgb(int x_pixel, int y_pixel,
                                                 const std::array<int, 6> &c,
                                                 std::array<std::uint64_t, 6> &hits) {
        if (x_pixel >= 640 || y_pixel >= 480)
            return {0, 0, 0};
        const int x = x_pixel - 320;
        const int y = 240 - y_pixel;
        const bool f2_enabled = c[3] != 0 || c[4] != 0 || c[5] != 0;
        int f1_vertex_x = 0, f1_vertex_y = 0, f2_vertex_x = 0, f2_vertex_y = 0;
        const bool f1_valid = vertexPixel(c[0], c[1], c[2], f1_vertex_x, f1_vertex_y);
        const bool f2_valid = f2_enabled && vertexPixel(c[3], c[4], c[5], f2_vertex_x, f2_vertex_y);
        bool f1_roots_valid = false, f2_roots_valid = false;
        const auto f1_roots = roots(c[0], c[1], c[2], f1_roots_valid);
        const auto f2_roots = roots(c[3], c[4], c[5], f2_roots_valid);
        const std::array<std::int64_t, 4> values = {
            functionY(c[0], c[1], c[2], x), derivativeY(c[0], c[1], x),
            functionY(c[3], c[4], c[5], x), derivativeY(c[3], c[4], x)};
        std::array<bool, 4> hit{};
        for (unsigned i = 0; i < hit.size(); ++i) {
            hit[i] = values[i] >= -239 && values[i] <= 240 && values[i] == y;
            if (i < 2 && !f1_valid)
                hit[i] = false;
            if (i >= 2 && !f2_valid)
                hit[i] = false;
            hits[i] += hit[i];
        }
        const bool intersection = f2_valid && hit[0] && hit[2] && values[0] == values[2];
        hits[5] += intersection;
        const bool axis = (x == 0 || y == 0);
        hits[4] += axis;
        if (intersection) return {15, 0, 15};
        const bool root_f1_eligible = f1_roots_valid;
        const bool root_f2_eligible = f2_enabled && f2_roots_valid;
        const std::array<int, 4> root_values = {f1_roots[0], f1_roots[1], f2_roots[0], f2_roots[1]};
        const std::array<bool, 4> root_eligible = {root_f1_eligible, root_f1_eligible,
                                                   root_f2_eligible, root_f2_eligible};
        const std::array<int, 4> label_y = {208, 216, 224, 232};
        const std::array<const char *, 4> label_prefix = {"F1x1=", "F1x2=", "F2x1=", "F2x2="};
        bool root_marker = false, root_label = false;
        for (unsigned i = 0; i < root_values.size(); ++i) {
            const int center_x = root_values[i];
            if (root_eligible[i] &&
                ((x == center_x && (y == -1 || y == 0 || y == 1)) ||
                 (y == 0 && (x == center_x - 1 || x == center_x + 1))))
                root_marker = true;
            if (root_eligible[i] && labelPixel(x_pixel, y_pixel, root_values[i], label_y[i], label_prefix[i]))
                root_label = true;
        }
        if (root_marker) return {15, 8, 0};
        if (root_label) return {15, 8, 0};
        const bool marker_f1 = f1_valid &&
                               ((x == f1_vertex_x && (y == f1_vertex_y - 1 || y == f1_vertex_y || y == f1_vertex_y + 1)) ||
                                (y == f1_vertex_y && (x == f1_vertex_x - 1 || x == f1_vertex_x + 1)));
        const bool marker_f2 = f2_valid &&
                               ((x == f2_vertex_x && (y == f2_vertex_y - 1 || y == f2_vertex_y || y == f2_vertex_y + 1)) ||
                                (y == f2_vertex_y && (x == f2_vertex_x - 1 || x == f2_vertex_x + 1)));
        if (marker_f1 || marker_f2) return {0, 15, 0};
        if (hit[0]) return {0, 0, 15};
        if (hit[1]) return {0, 15, 15};
        if (hit[2]) return {15, 0, 0};
        if (hit[3]) return {15, 15, 0};
        if (axis) return {15, 15, 15};
        return {0, 0, 0};
    }

    void pixelStep() {
        tick(3, 0);
        tick(3, 0);
    }

    struct PixelSample {
        std::array<unsigned, 3> rgb;
        int hs;
        int vs;
    };

    void scanFullFrame(const std::array<int, 6> &coefficients,
                       const std::string &label, std::uint64_t expected_intersections) {
        constexpr int frame_pixels = 800 * 525;
        constexpr int search_limit = 900000;
        if (label == "integer intersection x=0,y=0") {
            std::array<std::uint64_t, 6> probe_hits{};
            const auto probe = referenceRgb(638, 0, coefficients, probe_hits);
            require(probe == std::array<unsigned, 3>{0, 0, 0},
                    "reference probe for x=638,y=0 with integer-intersection coefficients must be black");
        }
        bool saw_vsync_high = false;
        int previous_vsync = dut.VGA_VS;
        const bool f2_enabled = coefficients[3] != 0 || coefficients[4] != 0 || coefficients[5] != 0;
        int aligned = false;
        for (int i = 0; i < search_limit; ++i) {
            pixelStep();
            const int vsync = dut.VGA_VS;
            if (vsync != 0) saw_vsync_high = true;
            if (saw_vsync_high && previous_vsync != 0 && vsync == 0) {
                aligned = true;
                std::cout << "TOP VERILATOR INFO: frame aligned at external VGA_VS falling edge\n";
                break;
            }
            previous_vsync = vsync;
        }
        require(aligned, "timeout waiting for external VGA_VS falling edge");

        std::vector<PixelSample> frame;
        frame.reserve(frame_pixels);
        std::vector<int> hs_fall_samples;
        int previous_hs = static_cast<int>(dut.VGA_HS);
        int previous_vs = static_cast<int>(dut.VGA_VS);
        int hs_low = 0, vs_low = 0, hs_falls = 0, vs_falls = 0;
        int vs_fall_sample = -1;
        for (int sample = 0; sample < frame_pixels; ++sample) {
            if (sample != 0)
                pixelStep();
            const int hs = dut.VGA_HS;
            const int vs = dut.VGA_VS;
            if (!hs && previous_hs) {
                ++hs_falls;
                hs_fall_samples.push_back(sample);
            }
            if (!vs && (previous_vs || sample == 0)) {
                ++vs_falls;
                vs_fall_sample = sample;
            }
            previous_hs = hs;
            previous_vs = vs;
            hs_low += !hs;
            vs_low += !vs;
            frame.push_back({{dut.VGA_R, dut.VGA_G, dut.VGA_B}, hs, vs});
            int marker_x = 0, marker_y = 0;
            const bool f1_error = coefficients[0] == 0 ||
                                  !vertexPixel(coefficients[0], coefficients[1], coefficients[2], marker_x, marker_y);
            const bool f2_error = f2_enabled &&
                                  (coefficients[3] == 0 ||
                                   !vertexPixel(coefficients[3], coefficients[4], coefficients[5], marker_x, marker_y));
            const unsigned expected_led = 2U | (f1_error ? 4U : 0U) | (f2_error ? 8U : 0U);
            expectEqual(led(), expected_led, "LEDR DONE/errors during frame");
        }
        require(hs_low == 96 * 525 && vs_low == 2 * 800 &&
                    hs_falls == 525 && vs_falls == 1,
                "unexpected full-frame active-low sync pulse counts: HS low=" +
                    std::to_string(hs_low) + " falls=" + std::to_string(hs_falls) +
                    " VS low=" + std::to_string(vs_low) + " falls=" +
                    std::to_string(vs_falls));
        require(hs_fall_samples.size() == 525, "wrong number of external HS falling edges");
        for (unsigned i = 1; i < hs_fall_samples.size(); ++i)
            require(hs_fall_samples[i] - hs_fall_samples[i - 1] == 800,
                    "HS falling edges are not 800 pixel periods apart");
        require((hs_fall_samples.front() + frame_pixels - hs_fall_samples.back()) == 800,
                "HS raster does not close at exactly 800 samples per line");
        require(vs_fall_sample >= 0, "VS falling edge was not located in the captured frame");

        const int x_at_start = (656 - (hs_fall_samples.front() % 800) + 800) % 800;
        const int lines_to_vs_fall = (x_at_start + vs_fall_sample) / 800;
        const int y_at_start = (513 - (lines_to_vs_fall % 525) + 525) % 525;
        std::array<std::uint64_t, 6> hits{};
        std::uint64_t observed_magenta = 0;
        bool origin_magenta = false;
        int active_pixels = 0, blanking_pixels = 0, panel_rgb_excluded = 0;
        if (label == "integer intersection x=0,y=0") {
            for (int sample = 0; sample < frame_pixels; ++sample) {
                const int raster_position = x_at_start + sample;
                const int x = raster_position % 800;
                const int y = (y_at_start + raster_position / 800) % 525;
                if (y == 0 && x >= 302 && x <= 305) {
                    const PixelSample &observed = frame[static_cast<std::size_t>(sample)];
                    std::cout << "TOP VERILATOR DEBUG external sample=" << sample << " raster=" << x << "," << y
                              << " HS/VS=" << observed.hs << "/" << observed.vs << " RGB="
                              << observed.rgb[0] << "," << observed.rgb[1] << "," << observed.rgb[2] << '\n';
                }
            }
        }
        for (int sample = 0; sample < frame_pixels; ++sample) {
            const int raster_position = x_at_start + sample;
            const int x = raster_position % 800;
            const int y = (y_at_start + raster_position / 800) % 525;
            const int expected_hs = !(x >= 656 && x <= 751);
            const int expected_vs = !(y >= 513 && y <= 514);
            const PixelSample &observed = frame[static_cast<std::size_t>(sample)];
            if (observed.hs != expected_hs || observed.vs != expected_vs) {
                throw std::runtime_error("sync phase mismatch at raster x=" + std::to_string(x) +
                                         " y=" + std::to_string(y) + ": observed HS/VS=" +
                                         std::to_string(observed.hs) + "/" + std::to_string(observed.vs) +
                                         " expected=" + std::to_string(expected_hs) + "/" +
                                         std::to_string(expected_vs));
            }
            const bool panel_pixel = x >= 520 && x <= 639 && y >= 300 && y <= 479;
            if (panel_pixel)
                ++panel_rgb_excluded;
            const auto expected = panel_pixel ? std::array<unsigned, 3>{0, 0, 0}
                                              : referenceRgb(x, y, coefficients, hits);
            if (observed.rgb == std::array<unsigned, 3>{15, 0, 15})
                ++observed_magenta;
            if (x == 320 && y == 240)
                origin_magenta = observed.rgb == std::array<unsigned, 3>{15, 0, 15};
            for (unsigned channel = 0; channel < 3 && !panel_pixel; ++channel) {
                if (observed.rgb[channel] != expected[channel]) {
                    throw std::runtime_error("RGB mismatch at sample=" + std::to_string(sample) +
                                             " raster x=" + std::to_string(x) + " y=" +
                                             std::to_string(y) + " channel=" +
                                             std::to_string(channel) + " expected=" +
                                             std::to_string(expected[channel]) + " observed=" +
                                             std::to_string(observed.rgb[channel]) +
                                             " expectedRGB=" + std::to_string(expected[0]) + "," +
                                             std::to_string(expected[1]) + "," +
                                             std::to_string(expected[2]) + " observedRGB=" +
                                             std::to_string(observed.rgb[0]) + "," +
                                             std::to_string(observed.rgb[1]) + "," +
                                             std::to_string(observed.rgb[2]));
                }
                ++checks;
            }
            if (x < 640 && y < 480) ++active_pixels;
            else ++blanking_pixels;
        }
        require(active_pixels == 640 * 480 && blanking_pixels == frame_pixels - 640 * 480,
                "active/blanking raster dimensions were not 640x480 within 800x525");
        require(panel_rgb_excluded == 21600,
                "RGB oracle must exclude exactly the 120x180 information-panel pixels");
        int checked_vertex_x = 0, checked_vertex_y = 0;
        const bool f1_valid = vertexPixel(coefficients[0], coefficients[1], coefficients[2],
                                          checked_vertex_x, checked_vertex_y);
        const bool f2_valid = f2_enabled &&
                              vertexPixel(coefficients[3], coefficients[4], coefficients[5],
                                          checked_vertex_x, checked_vertex_y);
        for (unsigned i = 0; i < 5; ++i) {
            if ((i < 2 && !f1_valid) || (i >= 2 && i < 4 && !f2_valid))
                continue;
            require(hits[i] != 0, "full frame did not exercise expected curve/axis index " +
                                       std::to_string(i));
        }
        require(hits[5] == expected_intersections,
                label + ": reference intersection count expected " +
                    std::to_string(expected_intersections) + ", observed " +
                    std::to_string(hits[5]));
        require(observed_magenta == expected_intersections,
                label + ": observed magenta pixel count expected " +
                    std::to_string(expected_intersections) + ", observed " +
                    std::to_string(observed_magenta));
        if (expected_intersections == 1)
            require(origin_magenta, label + ": integer intersection at the origin was not magenta");
        std::cout << "TOP VERILATOR INFO: external phase offsets x0=" << x_at_start
                  << " y0=" << y_at_start << "; VS falling at sample=" << vs_fall_sample
                  << " maps to line 513\n";
        std::cout << "TOP VERILATOR PASS: " << label << "; full frame 800x525; 840000 system clock cycles; "
                     "active=307200 blanking=112800; HS low=50400 VS low=1600; "
                     "four curves and axes; RGB panel samples excluded=" << panel_rgb_excluded
                  << "; magenta=" << observed_magenta << '\n';
    }

    void run() {
        const std::array<int, 6> integer_intersection = {1, 0, 0, 1, 1, 0};
        const std::array<int, 6> coincident = {1, 0, 0, 1, 0, 0};
        const std::array<int, 6> fractional_intersection = {1, 0, 0, 1, 3, 1};
        const std::array<int, 6> no_real_roots_valid_function = {1, 0, 1, 0, 0, 0};
        const std::array<int, 6> f2_disabled = {1, 0, 0, 0, 0, 0};
        const std::array<int, 6> both_a_zero = {0, 1, 0, 0, 1, 0};
        const std::array<int, 6> f1_vertex_out = {1, 127, 0, 1, 0, 0};
        const std::array<int, 6> f2_only_marker = {0, 0, 0, 1, 2, 1};
        const std::array<int, 6> vertices_on_active_y_edges = {-1, 22, 119, 1, 22, -118};
        const std::array<int, 6> f2_a_zero = {1, 0, 0, 0, 1, 0};
        const std::array<int, 6> f2_vertex_out = {1, 0, 0, 1, 127, 0};
        const std::array<int, 6> coefficient_limits = {-128, 0, 0, 127, 0, 0};
        const std::array<int, 6> negative_coordinate_tie = {1, 3, 1, 0, 0, 0};
        const std::array<int, 6> positive_coordinate_tie = {-1, 1, 0, 0, 0, 0};
        const std::array<int, 6> negative_half_boundary = {1, 1, 0, 0, 0, 0};
        const std::array<int, 6> negative_three_halves = {1, 3, 1, 0, 0, 0};
        const std::array<int, 6> positive_three_halves = {-1, 3, 0, 0, 0, 0};

        resetSession();
        cycles(2, 128, 7);
        cycles(3, 128, 7);
        expectStatus(0, -1);
        std::cout << "TOP VERILATOR PASS: invalid +128 rejected without advancing\n";
        clickKey0Raw(0x181, "invalid -129 rejected without advancing");
        clickKey0(1, "capture a1 after invalid entries");
        clickKey0Raw(0x100, "negative zero captured and normalized");
        clickKey0(0, "capture c1");
        clickKey0(0, "capture a2");
        clickKey0(0, "capture b2");
        clickKey0(0, "capture c2; review only");
        startProcessing(2, -1, "F1 valid and F2 disabled complete");
        startProcessing(2, -1, "reexecution revalidates retained coefficients");

        resetSession();
        captureTuple(integer_intersection);
        startProcessing(2, -1, "F1 and F2 valid before full-frame scan");
        scanFullFrame(integer_intersection, "integer intersection x=0,y=0", 1);

        resetSession();
        captureTuple(coincident);
        startProcessing(2, -1, "coincident functions complete");
        scanFullFrame(coincident, "coincident functions", 31);

        resetSession();
        captureTuple(fractional_intersection);
        startProcessing(2, -1, "fractional-only intersection functions valid");
        scanFullFrame(fractional_intersection, "fractional-only intersection x=-1/3", 0);

        resetSession();
        captureTuple(no_real_roots_valid_function);
        startProcessing(2, -1, "valid F1 parabola with negative discriminant");
        scanFullFrame(no_real_roots_valid_function, "negative discriminant suppresses roots only", 0);

        resetSession();
        captureTuple(negative_coordinate_tie);
        startProcessing(2, -1, "negative rational vertex coordinate");
        scanFullFrame(negative_coordinate_tie, "nearest-pixel vertex rounding, negative tie away from zero", 0);

        resetSession();
        captureTuple(negative_half_boundary);
        startProcessing(2, -1, "negative half tie at outer neighborhood boundary");
        scanFullFrame(negative_half_boundary, "n/d=-1/2 includes k=-2", 0);

        resetSession();
        captureTuple(negative_three_halves);
        startProcessing(2, -1, "negative three-halves outer neighborhood boundary");
        scanFullFrame(negative_three_halves, "n/d=-3/2 excludes k=0", 0);

        resetSession();
        captureTuple(positive_three_halves);
        startProcessing(2, -1, "positive three-halves outer neighborhood boundary");
        scanFullFrame(positive_three_halves, "n/d=+3/2 excludes k=0", 0);

        resetSession();
        captureTuple(positive_coordinate_tie);
        startProcessing(2, -1, "positive rational vertex coordinate");
        scanFullFrame(positive_coordinate_tie, "nearest-pixel vertex rounding, positive tie away from zero", 0);

        resetSession();
        captureTuple(f2_only_marker);
        startProcessing(6, 0, "F1 a=0 while F2 remains marker eligible");
        scanFullFrame(f2_only_marker, "F2 valid isolated marker with invalid F1", 0);

        resetSession();
        captureTuple(vertices_on_active_y_edges);
        startProcessing(2, -1, "valid F1/F2 vertices at both active y edges");
        scanFullFrame(vertices_on_active_y_edges, "upper/lower vertex crosses clipped at y=240/-239", 0);

        resetSession();
        captureTuple(f2_disabled);
        startProcessing(2, -1, "F2 null tuple disables intersections");
        scanFullFrame(f2_disabled, "F2 disabled", 0);

        resetSession();
        captureTuple(both_a_zero);
        startProcessing(14, 0, "both functions report a=0 with ERR F1 HEX priority");

        resetSession();
        captureTuple(f1_vertex_out);
        startProcessing(6, 1, "F1 vertex outside screen with valid F2");

        resetSession();
        captureTuple(f2_a_zero);
        startProcessing(10, 2, "valid F1 alongside F2 a=0 error");

        resetSession();
        captureTuple(f2_vertex_out);
        startProcessing(10, 3, "valid F1 alongside F2 vertex error");

        resetSession();
        captureTuple(coefficient_limits);
        startProcessing(2, -1, "signed coefficient limits -128 and 127 remain valid");
        std::cout << "TOP VERILATOR PASS: " << checks << " vector checks; "
                  << clock_cycles << " 20 ns system clock cycles\n";
    }
};

} // namespace

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    try {
        Scenario scenario;
        scenario.run();
        return 0;
    } catch (const std::exception &error) {
        std::cerr << "TOP VERILATOR FAIL: " << error.what() << '\n';
        return 1;
    }
}
