#define UNICODE
#define _UNICODE

#include <windows.h>
#include <gdiplus.h>

#include <cmath>
#include <memory>
#include <string>
#include <vector>

using Gdiplus::Bitmap;
using Gdiplus::Color;
using Gdiplus::Graphics;
using Gdiplus::Image;
using Gdiplus::Rect;

namespace {
constexpr int kWidth = 176;
constexpr int kHeight = 230;
constexpr int kFrameCount = 120;
constexpr UINT_PTR kAnimationTimer = 1;
constexpr UINT kFrameMilliseconds = 67;

enum class PetMode { Dance, Basketball };

HWND g_window = nullptr;
PetMode g_mode = PetMode::Dance;
int g_frame = 0;
POINT g_mouseDown{};
POINT g_windowAtMouseDown{};
bool g_dragged = false;
ULONG_PTR g_gdiplusToken = 0;
std::vector<std::unique_ptr<Bitmap>> g_danceFrames;
std::vector<std::unique_ptr<Bitmap>> g_basketballFrames;

std::wstring executableDirectory() {
    wchar_t buffer[MAX_PATH]{};
    GetModuleFileNameW(nullptr, buffer, MAX_PATH);
    std::wstring path(buffer);
    const auto slash = path.find_last_of(L"\\/");
    return slash == std::wstring::npos ? L"." : path.substr(0, slash);
}

bool loadSequence(const std::wstring& prefix, std::vector<std::unique_ptr<Bitmap>>& output) {
    const std::wstring directory = executableDirectory() + L"\\frames\\";
    for (int index = 1; index <= kFrameCount; ++index) {
        wchar_t filename[64]{};
        swprintf(filename, 64, L"%ls_%03d.png", prefix.c_str(), index);
        auto image = std::make_unique<Bitmap>((directory + filename).c_str(), FALSE);
        if (image->GetLastStatus() != Gdiplus::Ok) {
            MessageBoxW(
                nullptr,
                (L"无法读取动作帧：\n" + directory + filename).c_str(),
                L"只因你太美桌宠",
                MB_OK | MB_ICONERROR
            );
            return false;
        }
        output.push_back(std::move(image));
    }
    return true;
}

void renderFrame() {
    if (!g_window) {
        return;
    }

    auto& frames = g_mode == PetMode::Dance ? g_danceFrames : g_basketballFrames;
    if (frames.size() != kFrameCount) {
        return;
    }

    HDC screen = GetDC(nullptr);
    HDC memory = CreateCompatibleDC(screen);

    BITMAPINFO bitmapInfo{};
    bitmapInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmapInfo.bmiHeader.biWidth = kWidth;
    bitmapInfo.bmiHeader.biHeight = -kHeight;
    bitmapInfo.bmiHeader.biPlanes = 1;
    bitmapInfo.bmiHeader.biBitCount = 32;
    bitmapInfo.bmiHeader.biCompression = BI_RGB;

    void* pixels = nullptr;
    HBITMAP dib = CreateDIBSection(screen, &bitmapInfo, DIB_RGB_COLORS, &pixels, nullptr, 0);
    HGDIOBJ previous = SelectObject(memory, dib);

    {
        Graphics graphics(memory);
        graphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
        graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
        graphics.Clear(Color(0, 0, 0, 0));
        graphics.DrawImage(frames[g_frame].get(), Rect(0, 0, kWidth, kHeight));
    }

    POINT sourcePoint{0, 0};
    SIZE size{kWidth, kHeight};
    RECT current{};
    GetWindowRect(g_window, &current);
    POINT destination{current.left, current.top};
    BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
    UpdateLayeredWindow(
        g_window,
        screen,
        &destination,
        &size,
        memory,
        &sourcePoint,
        0,
        &blend,
        ULW_ALPHA
    );

    SelectObject(memory, previous);
    DeleteObject(dib);
    DeleteDC(memory);
    ReleaseDC(nullptr, screen);
}

void switchMode(PetMode mode) {
    g_mode = mode;
    g_frame = 0;
    renderFrame();
}

void showContextMenu(HWND window, int x, int y) {
    HMENU menu = CreatePopupMenu();
    AppendMenuW(
        menu,
        MF_STRING | (g_mode == PetMode::Dance ? MF_CHECKED : MF_UNCHECKED),
        1,
        L"只因你太美舞蹈"
    );
    AppendMenuW(
        menu,
        MF_STRING | (g_mode == PetMode::Basketball ? MF_CHECKED : MF_UNCHECKED),
        2,
        L"篮球运球"
    );
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, 3, L"退出桌宠");
    SetForegroundWindow(window);
    const UINT command = TrackPopupMenu(
        menu,
        TPM_RETURNCMD | TPM_RIGHTBUTTON,
        x,
        y,
        0,
        window,
        nullptr
    );
    DestroyMenu(menu);

    if (command == 1) {
        switchMode(PetMode::Dance);
    } else if (command == 2) {
        switchMode(PetMode::Basketball);
    } else if (command == 3) {
        DestroyWindow(window);
    }
}

LRESULT CALLBACK windowProcedure(HWND window, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CREATE:
        SetTimer(window, kAnimationTimer, kFrameMilliseconds, nullptr);
        return 0;
    case WM_TIMER:
        if (wParam == kAnimationTimer) {
            g_frame = (g_frame + 1) % kFrameCount;
            renderFrame();
        }
        return 0;
    case WM_LBUTTONDOWN: {
        SetCapture(window);
        GetCursorPos(&g_mouseDown);
        RECT rect{};
        GetWindowRect(window, &rect);
        g_windowAtMouseDown = POINT{rect.left, rect.top};
        g_dragged = false;
        return 0;
    }
    case WM_MOUSEMOVE:
        if ((wParam & MK_LBUTTON) != 0) {
            POINT current{};
            GetCursorPos(&current);
            const int dx = current.x - g_mouseDown.x;
            const int dy = current.y - g_mouseDown.y;
            if (std::abs(dx) >= 4 || std::abs(dy) >= 4) {
                g_dragged = true;
            }
            SetWindowPos(
                window,
                HWND_TOPMOST,
                g_windowAtMouseDown.x + dx,
                g_windowAtMouseDown.y + dy,
                0,
                0,
                SWP_NOSIZE | SWP_NOACTIVATE
            );
        }
        return 0;
    case WM_LBUTTONUP:
        ReleaseCapture();
        if (!g_dragged) {
            switchMode(g_mode == PetMode::Dance ? PetMode::Basketball : PetMode::Dance);
        }
        return 0;
    case WM_RBUTTONUP: {
        POINT cursor{};
        GetCursorPos(&cursor);
        showContextMenu(window, cursor.x, cursor.y);
        return 0;
    }
    case WM_DESTROY:
        KillTimer(window, kAnimationTimer);
        PostQuitMessage(0);
        return 0;
    default:
        return DefWindowProcW(window, message, wParam, lParam);
    }
}
}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int) {
    Gdiplus::GdiplusStartupInput input;
    if (Gdiplus::GdiplusStartup(&g_gdiplusToken, &input, nullptr) != Gdiplus::Ok) {
        return 1;
    }

    if (!loadSequence(L"dance", g_danceFrames) ||
        !loadSequence(L"basketball", g_basketballFrames)) {
        Gdiplus::GdiplusShutdown(g_gdiplusToken);
        return 2;
    }

    const wchar_t className[] = L"BasketPet120FrameWindow";
    WNDCLASSW windowClass{};
    windowClass.lpfnWndProc = windowProcedure;
    windowClass.hInstance = instance;
    windowClass.hCursor = LoadCursorW(nullptr, IDC_HAND);
    windowClass.lpszClassName = className;
    RegisterClassW(&windowClass);

    const int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    const int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    g_window = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
        className,
        L"只因你太美桌宠",
        WS_POPUP,
        screenWidth - kWidth - 28,
        screenHeight - kHeight - 70,
        kWidth,
        kHeight,
        nullptr,
        nullptr,
        instance,
        nullptr
    );
    if (!g_window) {
        Gdiplus::GdiplusShutdown(g_gdiplusToken);
        return 3;
    }

    ShowWindow(g_window, SW_SHOWNOACTIVATE);
    renderFrame();

    MSG message{};
    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }

    g_danceFrames.clear();
    g_basketballFrames.clear();
    Gdiplus::GdiplusShutdown(g_gdiplusToken);
    return static_cast<int>(message.wParam);
}
