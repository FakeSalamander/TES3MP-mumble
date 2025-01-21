#include "MumbleLink.hpp"

#include <algorithm>
#include <cstring>

#ifndef _WIN32
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#endif

namespace mwmp
{
    static float convert_to_meters = 0.0075f;
    LinkedMem *lm = NULL;

    void MumbleLink::initMumble()
    {

    #ifdef _WIN32
        HANDLE hMapObject = OpenFileMappingW(FILE_MAP_ALL_ACCESS, FALSE, L"MumbleLink");
        if (hMapObject == NULL)
            return;

        lm = (LinkedMem *)MapViewOfFile(hMapObject, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(LinkedMem));
        if (lm == NULL)
        {
            CloseHandle(hMapObject);
            hMapObject = NULL;
            return;
        }
    #else
        char memname[256];
        snprintf(memname, 256, "/MumbleLink.%d", getuid());

        int shmfd = shm_open(memname, O_RDWR, S_IRUSR | S_IWUSR);

        if (shmfd < 0)
        {
            return;
        }

        lm = (LinkedMem *)(mmap(NULL, sizeof(struct LinkedMem), PROT_READ | PROT_WRITE, MAP_SHARED, shmfd, 0));

        if (lm == (void *)(-1))
        {
            lm = NULL;
            return;
        }
    #endif
    }

    void MumbleLink::setContext(const std::string &context)
    {
        if (lm == NULL)
            return;

        // Context should be equal for players which should be able to hear each other positional and
        // differ for those who shouldn't (e.g. it could contain the server+port and team)
        size_t len(std::min(256, static_cast<int>(context.size())));
        std::memcpy(lm->context, context.c_str(), len);
        lm->context_len = static_cast<std::uint32_t>(len);
    }

    void MumbleLink::setIdentity(const std::string &identity)
    {
        if (lm == NULL)
            return;

        // Identifier which uniquely identifies a certain player in a context (e.g. the ingame name).
        wcsncpy(lm->identity, std::wstring(identity.begin(), identity.end()).c_str(), 256);
    }

    void MumbleLink::updateMumble(const osg::Vec3f &pos, const osg::Vec3f &forward, const osg::Vec3f &up)
    {
        if (!lm)
            return;

        if (lm->uiVersion != 2)
        {
            wcsncpy(lm->name, L"TES3MP", 256);
            wcsncpy(lm->description, L"Supports TES3MP.", 2048);
            lm->uiVersion = 2;
        }
        lm->uiTick++;

        osg::Vec3f front = { forward.x(), forward.z(), forward.y() };
        osg::Vec3f top = { up.x(), up.z(), up.y() };
        osg::Vec3f position = { pos.x(), pos.z(), pos.y() };

        // Left handed coordinate system.
        // X positive towards "right".
        // Y positive towards "up".
        // Z positive towards "front".
        //
        // 1 unit = 1 meter

        // Unit vector pointing out of the avatar's eyes aka "At"-vector.
        lm->fAvatarFront = front;

        // Unit vector pointing out of the top of the avatar's head aka "Up"-vector (here Top points straight up).
        lm->fAvatarTop = top;

        // Position of the avatar (here standing slightly off the origin)
        lm->fAvatarPosition = position * convert_to_meters;

        // Same as avatar but for the camera.
        lm->fCameraPosition = position * convert_to_meters;
        lm->fCameraFront = front;
        lm->fCameraTop = top;
    }
}