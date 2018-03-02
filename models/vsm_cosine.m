function cos = vsm_cosine(v1, v2)
% vsm_cosine() returns the cosine of the angle between v1 and v2 by
% computing the dot product between v1 and v2 after they have been
% normalized to unit length.
%
%      cos = vsm_cosine(v1, v2)
%

v1_norm = v1./sqrt(dot(v1, v1));
v2_norm = v2./sqrt(dot(v2, v2));

cos = dot(v1_norm, v2_norm);

end