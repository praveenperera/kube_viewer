use crate::{
    key_handler::{FocusRegion, KeyAwareEvent},
    main_view_model::{MainViewModelField, Updater},
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
                match self.tab_groups.previous_tab_group_id(id) {
                    Some(previous_tab_group_id) => {
                        self.key_handler.current_focus_region = SidebarGroup {
                            id: previous_tab_group_id,
                        };
                    }
                    None => self.key_handler.current_focus_region = FocusRegion::SidebarSearch,
                }

                true
            }

            (SidebarGroup { id }, TabKey) => {
                match self.tab_groups.next_tab_group_id(id) {
                    Some(next_tab_group_id) => {
                        self.key_handler.current_focus_region = SidebarGroup {
                            id: next_tab_group_id,
                        }
                    }
                    None => self.key_handler.current_focus_region = FocusRegion::ClusterSelection,
                }

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
                if let Some((tab_group_id, tab_id)) = self
                    .tab_groups
                    .0
                    .iter()
                    .find(|tab_group| &tab_group.id == id)
                    .map(|tab_group| (tab_group.id.clone(), tab_group.tabs.first()))
                    .and_then(|(tab_group_id, tab)| tab.map(|tab| (tab_group_id, tab.id.clone())))
                {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id,
                        tab_id: tab_id.clone(),
                    };

                    self.selected_tab = tab_id;
                    Updater::send(MainViewModelField::SelectedTab);

                    return true;
                }

                false
            }

            // next down in sidebar group

            // currently unhandled or ignored
            _ => false,
        }
    }
}
