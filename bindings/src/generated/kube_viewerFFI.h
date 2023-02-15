// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

#pragma once

#include <stdbool.h>
#include <stdint.h>

// The following structs are used to implement the lowest level
// of the FFI, and thus useful to multiple uniffied crates.
// We ensure they are declared exactly once, with a header guard, UNIFFI_SHARED_H.
#ifdef UNIFFI_SHARED_H
    // We also try to prevent mixing versions of shared uniffi header structs.
    // If you add anything to the #else block, you must increment the version suffix in UNIFFI_SHARED_HEADER_V4
    #ifndef UNIFFI_SHARED_HEADER_V4
        #error Combining helper code from multiple versions of uniffi is not supported
    #endif // ndef UNIFFI_SHARED_HEADER_V4
#else
#define UNIFFI_SHARED_H
#define UNIFFI_SHARED_HEADER_V4
// ⚠️ Attention: If you change this #else block (ending in `#endif // def UNIFFI_SHARED_H`) you *must* ⚠️
// ⚠️ increment the version suffix in all instances of UNIFFI_SHARED_HEADER_V4 in this file.           ⚠️

typedef struct RustBuffer
{
    int32_t capacity;
    int32_t len;
    uint8_t *_Nullable data;
} RustBuffer;

typedef int32_t (*ForeignCallback)(uint64_t, int32_t, RustBuffer, RustBuffer *_Nonnull);

typedef struct ForeignBytes
{
    int32_t len;
    const uint8_t *_Nullable data;
} ForeignBytes;

// Error definitions
typedef struct RustCallStatus {
    int8_t code;
    RustBuffer errorBuf;
} RustCallStatus;

// ⚠️ Attention: If you change this #else block (ending in `#endif // def UNIFFI_SHARED_H`) you *must* ⚠️
// ⚠️ increment the version suffix in all instances of UNIFFI_SHARED_HEADER_V4 in this file.           ⚠️
#endif // def UNIFFI_SHARED_H

void ffi_kube_viewer_54fe_RustMainViewModel_object_free(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void*_Nonnull kube_viewer_54fe_RustMainViewModel_new(
      
    RustCallStatus *_Nonnull out_status
    );
RustBuffer _uniffi_kube_viewer_impl_RustMainViewModel_selected_tab_9ae(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void _uniffi_kube_viewer_impl_RustMainViewModel_set_selected_tab_48a9(
      void*_Nonnull ptr,RustBuffer selected_tab,
    RustCallStatus *_Nonnull out_status
    );
void _uniffi_kube_viewer_impl_RustMainViewModel_set_tab_group_expansions_ac8c(
      void*_Nonnull ptr,RustBuffer tab_group_expansions,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer _uniffi_kube_viewer_impl_RustMainViewModel_tab_group_expansions_8bbf(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer _uniffi_kube_viewer_impl_RustMainViewModel_tab_groups_f31a(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer _uniffi_kube_viewer_impl_RustMainViewModel_tabs_57ab(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer _uniffi_kube_viewer_impl_RustMainViewModel_tabs_map_4669(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_kube_viewer_54fe_rustbuffer_alloc(
      int32_t size,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_kube_viewer_54fe_rustbuffer_from_bytes(
      ForeignBytes bytes,
    RustCallStatus *_Nonnull out_status
    );
void ffi_kube_viewer_54fe_rustbuffer_free(
      RustBuffer buf,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_kube_viewer_54fe_rustbuffer_reserve(
      RustBuffer buf,int32_t additional,
    RustCallStatus *_Nonnull out_status
    );
