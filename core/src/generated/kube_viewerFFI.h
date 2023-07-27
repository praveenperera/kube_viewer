// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

#pragma once

#include <stdbool.h>
#include <stddef.h>
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

typedef int32_t (*ForeignCallback)(uint64_t, int32_t, const uint8_t *_Nonnull, int32_t, RustBuffer *_Nonnull);

// Task defined in Rust that Swift executes
typedef void (*UniFfiRustTaskCallback)(const void * _Nullable);

// Callback to execute Rust tasks using a Swift Task
//
// Args:
//   executor: ForeignExecutor lowered into a size_t value
//   delay: Delay in MS
//   task: UniFfiRustTaskCallback to call
//   task_data: data to pass the task callback
typedef void (*UniFfiForeignExecutorCallback)(size_t, uint32_t, UniFfiRustTaskCallback _Nullable, const void * _Nullable);

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

// Callbacks for UniFFI Futures
typedef void (*UniFfiFutureCallbackUInt8)(const void * _Nonnull, uint8_t, RustCallStatus);
typedef void (*UniFfiFutureCallbackInt8)(const void * _Nonnull, int8_t, RustCallStatus);
typedef void (*UniFfiFutureCallbackUInt64)(const void * _Nonnull, uint64_t, RustCallStatus);
typedef void (*UniFfiFutureCallbackUnsafeMutableRawPointer)(const void * _Nonnull, void*_Nonnull, RustCallStatus);
typedef void (*UniFfiFutureCallbackUnsafeMutableRawPointer)(const void * _Nonnull, void*_Nonnull, RustCallStatus);
typedef void (*UniFfiFutureCallbackUnsafeMutableRawPointer)(const void * _Nonnull, void*_Nonnull, RustCallStatus);
typedef void (*UniFfiFutureCallbackUnsafeMutableRawPointer)(const void * _Nonnull, void*_Nonnull, RustCallStatus);
typedef void (*UniFfiFutureCallbackRustBuffer)(const void * _Nonnull, RustBuffer, RustCallStatus);

// Scaffolding functions
void uniffi_kube_viewer_fn_free_focusregionhasher(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void*_Nonnull uniffi_kube_viewer_fn_constructor_focusregionhasher_new(RustCallStatus *_Nonnull out_status
    
);
uint64_t uniffi_kube_viewer_fn_method_focusregionhasher_hash(void*_Nonnull ptr, RustBuffer value, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_free_rustnodeviewmodel(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void*_Nonnull uniffi_kube_viewer_fn_constructor_rustnodeviewmodel_new(RustBuffer window_id, RustCallStatus *_Nonnull out_status
);
void*_Nonnull uniffi_kube_viewer_fn_constructor_rustnodeviewmodel_preview(RustBuffer window_id, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustnodeviewmodel_add_callback_listener(void*_Nonnull ptr, uint64_t responder, size_t uniffi_executor, UniFfiFutureCallbackUInt8 _Nonnull uniffi_callback, void* _Nonnull uniffi_callback_data, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustnodeviewmodel_fetch_nodes(void*_Nonnull ptr, RustBuffer selected_cluster, size_t uniffi_executor, UniFfiFutureCallbackUInt8 _Nonnull uniffi_callback, void* _Nonnull uniffi_callback_data, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustnodeviewmodel_nodes(void*_Nonnull ptr, RustBuffer selected_cluster, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustnodeviewmodel_refresh_nodes(void*_Nonnull ptr, RustBuffer selected_cluster, size_t uniffi_executor, UniFfiFutureCallbackUInt8 _Nonnull uniffi_callback, void* _Nonnull uniffi_callback_data, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustnodeviewmodel_stop_watcher(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_free_rustglobalviewmodel(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void*_Nonnull uniffi_kube_viewer_fn_constructor_rustglobalviewmodel_new(RustCallStatus *_Nonnull out_status
    
);
void uniffi_kube_viewer_fn_method_rustglobalviewmodel_add_callback_listener(void*_Nonnull ptr, uint64_t responder, size_t uniffi_executor, UniFfiFutureCallbackUInt8 _Nonnull uniffi_callback, void* _Nonnull uniffi_callback_data, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustglobalviewmodel_clusters(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustglobalviewmodel_load_client(void*_Nonnull ptr, RustBuffer cluster_id, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_free_rustmainviewmodel(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void*_Nonnull uniffi_kube_viewer_fn_constructor_rustmainviewmodel_new(RustBuffer window_id, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_add_update_listener(void*_Nonnull ptr, uint64_t updater, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_async_do(void*_Nonnull ptr, size_t uniffi_executor, UniFfiFutureCallbackUInt8 _Nonnull uniffi_callback, void* _Nonnull uniffi_callback_data, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_current_focus_region(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
int8_t uniffi_kube_viewer_fn_method_rustmainviewmodel_handle_key_input(void*_Nonnull ptr, RustBuffer key_input, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_select_first_filtered_tab(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_selected_cluster(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_selected_tab(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_set_current_focus_region(void*_Nonnull ptr, RustBuffer current_focus_region, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_set_selected_cluster(void*_Nonnull ptr, RustBuffer cluster, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_set_selected_tab(void*_Nonnull ptr, RustBuffer selected_tab, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_set_tab_group_expansions(void*_Nonnull ptr, RustBuffer tab_group_expansions, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_method_rustmainviewmodel_set_window_closed(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_tab_group_expansions(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_tab_groups_filtered(void*_Nonnull ptr, RustBuffer search, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_tabs(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_method_rustmainviewmodel_tabs_map(void*_Nonnull ptr, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_init_callback_globalviewmodelcallback(ForeignCallback _Nonnull callback_stub, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_init_callback_mainviewmodelupdater(ForeignCallback _Nonnull callback_stub, RustCallStatus *_Nonnull out_status
);
void uniffi_kube_viewer_fn_init_callback_nodeviewmodelcallback(ForeignCallback _Nonnull callback_stub, RustCallStatus *_Nonnull out_status
);
RustBuffer uniffi_kube_viewer_fn_func_node_preview(RustCallStatus *_Nonnull out_status
    
);
RustBuffer ffi_kube_viewer_rustbuffer_alloc(int32_t size, RustCallStatus *_Nonnull out_status
);
RustBuffer ffi_kube_viewer_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus *_Nonnull out_status
);
void ffi_kube_viewer_rustbuffer_free(RustBuffer buf, RustCallStatus *_Nonnull out_status
);
RustBuffer ffi_kube_viewer_rustbuffer_reserve(RustBuffer buf, int32_t additional, RustCallStatus *_Nonnull out_status
);
uint16_t uniffi_kube_viewer_checksum_func_node_preview(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_focusregionhasher_hash(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustnodeviewmodel_add_callback_listener(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustnodeviewmodel_fetch_nodes(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustnodeviewmodel_nodes(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustnodeviewmodel_refresh_nodes(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustnodeviewmodel_stop_watcher(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustglobalviewmodel_add_callback_listener(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustglobalviewmodel_clusters(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustglobalviewmodel_load_client(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_add_update_listener(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_async_do(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_current_focus_region(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_handle_key_input(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_select_first_filtered_tab(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_selected_cluster(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_selected_tab(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_set_current_focus_region(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_set_selected_cluster(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_set_selected_tab(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_set_tab_group_expansions(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_set_window_closed(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_tab_group_expansions(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_tab_groups_filtered(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_tabs(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_rustmainviewmodel_tabs_map(void
    
);
uint16_t uniffi_kube_viewer_checksum_constructor_focusregionhasher_new(void
    
);
uint16_t uniffi_kube_viewer_checksum_constructor_rustnodeviewmodel_new(void
    
);
uint16_t uniffi_kube_viewer_checksum_constructor_rustnodeviewmodel_preview(void
    
);
uint16_t uniffi_kube_viewer_checksum_constructor_rustglobalviewmodel_new(void
    
);
uint16_t uniffi_kube_viewer_checksum_constructor_rustmainviewmodel_new(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_globalviewmodelcallback_callback(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_mainviewmodelupdater_update(void
    
);
uint16_t uniffi_kube_viewer_checksum_method_nodeviewmodelcallback_callback(void
    
);
void uniffi_foreign_executor_callback_set(UniFfiForeignExecutorCallback _Nonnull callback
);
uint32_t ffi_kube_viewer_uniffi_contract_version(void
    
);

