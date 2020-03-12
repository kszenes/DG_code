function [rhsu] = compute_rhs_new(u_new,r_new,n_qp_1D,phi_val_cell,phi_grad_cell_x,phi_grad_cell_y,...
                                  phi_val_bd_cell_n,phi_val_bd_cell_s,phi_val_bd_cell_e,phi_val_bd_cell_w,inv_mass,...
                                  hx,hy,wts,wts2d,radius,pts_x,pts_y,pts2d_x,pts2d_y,x_c,y_c,coriolis_fun,eq_type)
%compute rsh of the ode

%dimension: (cardinality)*(num_elems)*(num_eqns)
d1=size(u_new,1);
d2=size(u_new,2);
neq=size(u_new,3);

rshu = cell(size(u_new));

%
% Allocate RHS
for i=1:d1
    for j=1:d2
        for n=1:neq
            rhsu{i,j,n}=zeros(size(u_new{i,j,n}));
        end
    end
end

%cardinality and qp
dim=(max(r_new(:))+1)^2;
n_qp=n_qp_1D^2;

%determinants of the internal and boundary mappings: 1=bottom, 2=right, 3=top, 4=left
determ=hx*hy/4;
bd_det(1)=hx/2; bd_det(2)=hy/2; bd_det(3)=hx/2; bd_det(4)=hy/2;

%compute solution in the quadrature points (sort of modal to nodal
%conversion)
u_qp_new=cell(size(u_new));

for i=1:d1
    for j=1:d2
        for n=1:neq
            u_qp_new{i,j,n}=phi_val_cell{r_new(i,j)}*u_new{i,j,n};
        end
    end
end

%INTERNAL INTEGRALS

%compute physical value of F(x) inside the region 
[flux_fun_x_new, flux_fun_y_new]=flux_function_new(u_qp_new,eq_type,radius,hx,hy,x_c,y_c,pts2d_x,pts2d_y);

%compute internal integral and add it to the rhs
%det_internal*inverse_of_jacobian_x_affine*sum(dPhi/dr*f_x*weights)+
%det_internal*inverse_of_jacobian_y_affine*sum(dPhi/ds*f_y*weights)

if eq_type=="linear" || eq_type=="swe"
% Cartesian geometry
    for i=1:d1
        for j=1:d2
            for n=1:neq
                rhsu{i,j,n}=phi_grad_cell_x{r_new(i,j)}'*(flux_fun_x_new{i,j,n}.*wts2d)*(2/hx)*determ +...
                            phi_grad_cell_y{r_new(i,j)}'*(flux_fun_y_new{i,j,n}.*wts2d)*(2/hy)*determ;
            end
        end
    end
end

if eq_type=="adv_sphere" || eq_type=="swe_sphere"
%Spherical geometry
    for i=1:d1
        for j=1:d2
            for n=1:neq
%calculate qp_y on the fly
                qp_y=y_c(j)+pts2d_y/2*hy;
                rhsu{i,j,n}=phi_grad_cell_x{r_new(i,j)}'*(flux_fun_x_new{i,j,n}.*wts2d)*(2/hx)*determ +...
                            phi_grad_cell_y{r_new(i,j)}'*(cos(qp_y).*flux_fun_y_new{i,j,n}.*wts2d)*(2/hy)*determ;
%                max_rhs_u=[i j max(rhsu{i,j,n})]
            end
        end
    end
end


%BOUNDARY INTEGRALS

%compute solution in the boundary quadrature points (sort of modal to nodal
%conversion)
%dimension: (num_bd_qp)*(cardinality)*num_faces*num_equations

u_qp_bd_n=cell(d1,d2,neq);
u_qp_bd_s=cell(d1,d2,neq);
u_qp_bd_e=cell(d1,d2,neq);
u_qp_bd_w=cell(d1,d2,neq);

for i=1:d1
    for j=1:d2
        for n=1:neq
            u_qp_bd_n{i,j,n} = phi_val_bd_cell_n{r_new(i,j)}*u_new{i,j,n}; 
            u_qp_bd_s{i,j,n} = phi_val_bd_cell_s{r_new(i,j)}*u_new{i,j,n}; 
            u_qp_bd_e{i,j,n} = phi_val_bd_cell_e{r_new(i,j)}*u_new{i,j,n}; 
            u_qp_bd_w{i,j,n} = phi_val_bd_cell_w{r_new(i,j)}*u_new{i,j,n}; 
        end
    end
end

%%% phi_val_bd_cell_n_2 = phi_val_bd_cell_n{2}
u_qp_bd_n_7_5 = u_qp_bd_n{7,5,1}

%compute LF fluxes on all four edges
%  First cut: calculate all edges simultaneously
%%%% [flux_n,flux_s,flux_e,flux_w]=compute_numerical_flux_new(u_qp_bd_n,u_qp_bd_s,u_qp_bd_e,u_qp_bd_w,...
%%%%                                                         pts_x,pts_y,d1,d2,neq,hx,hy,eq_type,radius,x_c,y_c);

% Better: calculate each edge separately using a generic boundary flux computation

flux_n = comp_flux_generic_bd(u_qp_bd_n,0,1,pts_x,d1,d2,neq,hx,hy,eq_type,radius,x_c,y_c);
flux_s = comp_flux_generic_bd(u_qp_bd_s,0,-1,pts_x,d1,d2,neq,hx,hy,eq_type,radius,x_c,y_c);
flux_e = comp_flux_generic_bd(u_qp_bd_e,1,0,pts_y,d1,d2,neq,hx,hy,eq_type,radius,x_c,y_c);
flux_w = comp_flux_generic_bd(u_qp_bd_w,-1,0,pts_y,d1,d2,neq,hx,hy,eq_type,radius,x_c,y_c);

%compute boundary integrals and subtract them from the rhs
%%%bd_term=zeros(size(u));
for n=1:neq
    for i=1:4
        %det_bd*sum(Phi*num_flux*weights)
%%%        bd_term(:,:,n)=bd_term(:,:,n)+reshape(phi_val_bd{i}'*reshape(num_flux(:,:,i,n).*wts,n_qp_1D*d1*d2,1),dim,d1*d2)*bd_det(i);
        %bd_term(:,:,n)=bd_term(:,:,n)+phi_val_bd(:,:,i)'*(num_flux(:,:,i,n).*wts)*bd_det(i);
    end
%%%    rhsu(:,:,n)=rhsu(:,:,n)-bd_term(:,:,n);
end

for i=1:d1
    for j=1:d2
        for n=1:neq
            rhsu{i,j,n} = rhsu{i,j,n} - 0.5*hy*phi_val_bd_cell_n{r_new(i,j)}'*(flux_n{i,j,n}.*wts)... 
                                      - 0.5*hy*phi_val_bd_cell_s{r_new(i,j)}'*(flux_s{i,j,n}.*wts)...
                                      - 0.5*hx*phi_val_bd_cell_e{r_new(i,j)}'*(flux_e{i,j,n}.*wts)...
                                      - 0.5*hx*phi_val_bd_cell_w{r_new(i,j)}'*(flux_w{i,j,n}.*wts);
        end
    end
end

%add corrective internal term for the divergence, only in SWE spherical coordinates
if eq_type=="swe_sphere"

						 % NOT CURRENTLY SUPPORTED
						 
    %rhsu(:,:,2)=rhsu(:,:,2)+phi_val'*(complem_fact.*flux_fun_y(:,:,2).*wts2d)*determ;
    %rhsu(:,:,3)=rhsu(:,:,3)-phi_val'*(complem_fact.*flux_fun_x(:,:,2).*wts2d)*determ;
end


%add coriolis term to second and third equation of the swe
if eq_type=="swe" || eq_type=="swe_sphere"

						 % NOT CURRENTLY SUPPORTED

%%%    coriolis=coriolis_fun(pts2d_phi(1:n_qp,:),pts2d_phi(n_qp+1:2*n_qp,:));
    %rhsu(:,:,2)=rhsu(:,:,2)+radius*phi_val(:,:)'*(fact_int.*coriolis.*u_qp(:,:,3).*wts2d)*determ;
	%rhsu(:,:,3)=rhsu(:,:,3)-radius*phi_val(:,:)'*(fact_int.*coriolis.*u_qp(:,:,2).*wts2d)*determ;
end

%invert the (local) mass matrix and divide by radius

for i=1:d1
    for j=1:d2
        for n=1:neq
            rhsu{i,j,n} = 1/radius * inv_mass{i,j}*rhsu{i,j,n};
        end
    end
end

end
