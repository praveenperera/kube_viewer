use tab::{BorrowedTabs, TabId, Tabs};

use crate::{
    key_handler::{FocusRegion, KeyAwareEvent},
    main_view_model::{MainViewModelField, Updater},
    tab,
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

            (InTabGroup { tab_group_id, .. }, ShiftTab) => {
                match self.tab_groups.previous_tab_group_id(tab_group_id) {
                    Some(previous_tab_group_id) => {
                        self.key_handler.current_focus_region = SidebarGroup {
                            id: previous_tab_group_id,
                        };
                    }
                    None => self.key_handler.current_focus_region = FocusRegion::SidebarSearch,
                }

                true
            }

            (InTabGroup { tab_group_id, .. }, TabKey) => {
                match self.tab_groups.next_tab_group_id(tab_group_id) {
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
                if let Some(tab) = self
                    .tab_groups
                    .get_by_id(id)
                    .and_then(|tab_group| tab_group.tabs.first())
                {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id: id.clone(),
                        tab_id: tab.id.clone(),
                    };

                    self.selected_tab = tab.id.clone();

                    Updater::send(MainViewModelField::SelectedTab);

                    return true;
                }

                false
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
                        self.selected_tab = next_tab_id.clone();
                        next_tab_id
                    } else {
                        let first_tab_id = tab_group.tabs.first()?.id.clone();
                        self.selected_tab = first_tab_id.clone();
                        first_tab_id
                    };

                    Some(next_tab_id)
                })();

                if let Some(next_tab_id) = next_tab_id {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id: tab_group_id.clone(),
                        tab_id: next_tab_id,
                    };

                    Updater::send(MainViewModelField::SelectedTab);
                }

                false
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
                        self.selected_tab = previous_tab_id.clone();
                        previous_tab_id
                    } else {
                        let last_tab_id = tab_group.tabs.last()?.id.clone();
                        self.selected_tab = last_tab_id.clone();
                        last_tab_id
                    };

                    Some(previous_tab_id)
                })();

                if let Some(previous_tab_id) = previous_tab_id {
                    self.key_handler.current_focus_region = FocusRegion::InTabGroup {
                        tab_group_id: tab_group_id.clone(),
                        tab_id: previous_tab_id,
                    };

                    Updater::send(MainViewModelField::CurrentFocusRegion);
                    Updater::send(MainViewModelField::SelectedTab);
                }

                false
            }

            // currently unhandled or ignored
            _ => false,
        }
    }
}
