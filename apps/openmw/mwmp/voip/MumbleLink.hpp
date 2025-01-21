#ifndef OPENMW_MUMBLELINK_HPP
#define OPENMW_MUMBLELINK_HPP

#include <osg/Vec3f>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

struct LinkedMem
{
#ifdef WIN32
    UINT32 uiVersion;
    DWORD uiTick;
#else
    uint32_t uiVersion;
    uint32_t uiTick;
#endif
    osg::Vec3f fAvatarPosition;
    osg::Vec3f fAvatarFront;
    osg::Vec3f fAvatarTop;
    wchar_t name[256];
    osg::Vec3f fCameraPosition;
    osg::Vec3f fCameraFront;
    osg::Vec3f fCameraTop;
    wchar_t identity[256];
#ifdef WIN32
    UINT32 context_len;
#else
    uint32_t context_len;
#endif
    unsigned char context[256];
    wchar_t description[2048];
};

namespace mwmp
{
    class MumbleLink
    {
    public:
        static void initMumble();
        static void setContext(const std::string &context);
        static void setIdentity(const std::string &identity);
        static void updateMumble(const osg::Vec3f &pos, const osg::Vec3f &forward, const osg::Vec3f &up);
    };
}

#endif