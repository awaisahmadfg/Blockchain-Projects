  GET_WORKPLACE_TAGS_SUCCESS,
  GET_LOCATION_TAGS,
  GET_WORKPLACE_TAGS,
  GET_UNIVERSITY_TAGS,
  GET_UNIVERSITY_TAGS_SUCCESS,
  GET_RELATED_TAGS_SUCCESS
} from './types';
@@ -20,12 +21,15 @@ const INITIAL_STATE = {
  companies: [],
  tags: [],
  locationTags: [],
  locationTagsLoading: false,
  locationTagsCount: 0,
  tagsCount: 0,
  tagsLoader: false,
  workplaceTags: [],
  workplaceTagsLoading: false,
  workplaceTagsCount: 0,
  universityTags: [],
  universityTagsLoading: false,
  universityTagsCount: 0,
  relatedTags: [],
  relatedTagsCount: 0
};
const reducer = (
  state = INITIAL_STATE,
  action: { type: string; payload: any }
) => {
  switch (action.type) {
    case GET_PRODUCTS:
      return { ...state, loading: true };
    case GET_PRODUCTS_SUCCESS:
      return { ...state, products: action.payload, loading: false };
    case GET_COMPANIES:
      return { ...state, loading: true };
    case GET_TAGS:
      return { ...state, loading: true };
    case GET_COMPANIES_SUCCESS:
      return { ...state, companies: action.payload, loading: false };
    case GET_TAGS_LOADER:
      return { ...state, tagsLoader: action.payload };
    case GET_TAGS_SUCCESS:
@@ -56,27 +60,29 @@
        tagsCount: action.payload.total
      };
    case GET_LOCATION_TAGS:
      return { ...state, loading: true };
      return { ...state, locationTagsLoading: true };
    case GET_WORKPLACE_TAGS:
      return { ...state, loading: true };
      return { ...state, workplaceTagsLoading: true };
    case GET_UNIVERSITY_TAGS:
      return { ...state, universityTagsLoading: true };
    case GET_LOCATION_TAGS_SUCCESS:
      return {
        ...state,
        loading: false,
        locationTagsLoading: false,
        locationTags: action.payload.data,
        locationTagsCount: action.payload.total
      };
    case GET_WORKPLACE_TAGS_SUCCESS:
      return {
        ...state,
        loading: false,
        workplaceTagsLoading: false,
        workplaceTags: action.payload.data,
        workplaceTagsCount: action.payload.total
      };
    case GET_UNIVERSITY_TAGS_SUCCESS:
      return {
        ...state,
        loading: false,
        universityTagsLoading: false,
        universityTags: action.payload.data,
        universityTagsCount: action.payload.total
      };
