use tab::{BorrowedTabs, TabId};

use crate::{
    key_handler::{FocusRegion, KeyAwareEvent},
    main_view_model::{MainViewModelField, Updater},
    tab,
    tab_group::TabGroups,
    TabGroupId,
};

use super::MainViewModel;

impl MainViewModel {
    pub fn handle_key_input(&mut self, key_input: KeyAwareEvent) -> bool {
        use FocusRegion::*;
        use KeyAwareEvent::*;

        match (&self.key_handler.current_focus_region, &key_input) {
            (SidebarSearch, TabKey) => {
                if !self.tab_groups.0.is_empty() {
                    self.key_handler.current_focus_region = SidebarGroup {
                        id: self.tab_groups.0[0].id.clone(),
                    };
                } else {
                    self.key_handler.current_focus_region = FocusRegion::Content;
                }

                true
            }

            (SidebarGroup { id }, ShiftTab) => {
                self.key_handler.current_focus_region =
                    get_previous_tab_group_focus(&self.tab_groups, id);

                true
            }

            (SidebarGroup { id }, TabKey) => {
                self.key_handler.current_focus_region =
                    get_next_tab_group_focus(&self.tab_groups, id);
                true
            }

            (InTabGroup { tab_group_id, .. }, ShiftTab) => {
                self.key_handler.current_focus_region =
                    get_previous_tab_group_focus(&self.tab_groups, tab_group_id);

                true
            }

            (InTabGroup { tab_group_id, .. }, TabKey) => {
                self.key_handler.current_focus_region =
                    get_next_tab_group_focus(&self.tab_groups, tab_group_id);

                true
            }

            (ClusterSelection, TabKey) => {
                self.key_handler.current_focus_region = FocusRegion::Content;
                true
            }

            (ClusterSelection, ShiftTab) => {
                if !self.tab_groups.0.is_empty() {
                    let last_index = self.tab_groups.0.len() - 1;
                    self.key_handler.current_focus_region = SidebarGroup {
                        id: self.tab_groups.0[last_index].id.clone(),
                    };
                } else {
                    self.key_handler.current_focus_region = FocusRegion::SidebarSearch;
                }
                true
            }

            (Content, ShiftTab) => {
                self.key_handler.current_focus_region = FocusRegion::ClusterSelection;
                true
            }

            // content --> siebar search
            (Content, TabKey) => {
                self.key_handler.current_focus_region = FocusRegion::SidebarSearch;
                true
            }

            // escape out of focused
            (SidebarGroup { .. } | SidebarSearch, Escape) => {
                self.key_handler.current_focus_region = FocusRegion::Content;
                true
            }

            // start into sidebar group
            (SidebarGroup { id }, DownArrow) => {
                if let Some(tab) = self
                    .tab_groups
                    .get_by_id(id)
                    .and_then(|tab_group| tab_group.tabs.first())
                {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id: id.clone(),
                        tab_id: tab.id.clone(),
                    };

                    self.select_tab(tab.id.clone());

                    Updater::send(&self.window_id, MainViewModelField::SelectedTab);

                    return true;
                }

                true
            }

            // start into bottom of sidebar group
            (SidebarGroup { id }, UpArrow) => {
                if let Some(tab) = self
                    .tab_groups
                    .get_by_id(id)
                    .and_then(|tab_group| tab_group.tabs.last())
                {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id: id.clone(),
                        tab_id: tab.id.clone(),
                    };

                    self.select_tab(tab.id.clone());

                    Updater::send(&self.window_id, MainViewModelField::SelectedTab);

                    return true;
                }

                true
            }

            // next down in sidebar group
            (
                InTabGroup {
                    tab_group_id,
                    tab_id,
                },
                DownArrow,
            ) => {
                let next_tab_id: Option<TabId> = (|| {
                    let tab_group = self.tab_groups.get_by_id(tab_group_id)?.clone();
                    let next_tab_id = BorrowedTabs::from(&tab_group.tabs).next_tab_id(tab_id);

                    let next_tab_id = if let Some(next_tab_id) = next_tab_id {
                        next_tab_id
                    } else {
                        tab_group.tabs.first()?.id.clone()
                    };

                    Some(next_tab_id)
                })();

                if let Some(next_tab_id) = next_tab_id {
                    let tab_group_id = tab_group_id.clone();
                    self.select_tab(next_tab_id.clone());

                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id,
                        tab_id: next_tab_id,
                    };

                    Updater::send(&self.window_id, MainViewModelField::SelectedTab);
                }

                true
            }

            // next up in sidebar group
            (
                InTabGroup {
                    tab_group_id,
                    tab_id,
                },
                UpArrow,
            ) => {
                let previous_tab_id: Option<TabId> = (|| {
                    let tab_group = self.tab_groups.get_by_id(tab_group_id)?.clone();
                    let previous_tab_id =
                        BorrowedTabs::from(&tab_group.tabs).previous_tab_id(tab_id);

                    let previous_tab_id = if let Some(previous_tab_id) = previous_tab_id {
                        previous_tab_id
                    } else {
                        let last_tab_id = tab_group.tabs.last()?.id.clone();
                        last_tab_id
                    };

                    Some(previous_tab_id)
                })();

                if let Some(previous_tab_id) = previous_tab_id {
                    let tab_group_id = tab_group_id.clone();
                    self.select_tab(previous_tab_id.clone());

                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id,
                        tab_id: previous_tab_id,
                    };

                    Updater::send(&self.window_id, MainViewModelField::SelectedTab);
                }

                true
            }

            // toggle sidebar group extension
            (
                InTabGroup {
                    tab_group_id: id, ..
                }
                | SidebarGroup { id },
                Space | Enter,
            ) => {
                if let Some(is_expanded) = self.tab_group_expansions.get_mut(id) {
                    *is_expanded = !*is_expanded;
                    Updater::send(&self.window_id, MainViewModelField::TabGroupExpansions);
                }

                true
            }

            (_, OptionF) => {
                self.key_handler.current_focus_region = FocusRegion::SidebarSearch;
                true
            }

            // currently unhandled or ignored
            _ => false,
        }
    }
}

fn get_next_tab_group_focus(tab_groups: &TabGroups, tab_group_id: &TabGroupId) -> FocusRegion {
    match tab_groups.next_tab_group_id(tab_group_id) {
        Some(next_tab_group_id) => FocusRegion::SidebarGroup {
            id: next_tab_group_id,
        },
        None => FocusRegion::ClusterSelection,
    }
}

fn get_previous_tab_group_focus(tab_groups: &TabGroups, tab_group_id: &TabGroupId) -> FocusRegion {
    match tab_groups.previous_tab_group_id(tab_group_id) {
        Some(previous_tab_group_id) => FocusRegion::SidebarGroup {
            id: previous_tab_group_id,
        },
        None => FocusRegion::SidebarSearch,
    }
}
